from __future__ import annotations

import argparse
import base64
import re
import shutil
import sys
import tempfile
import time
from pathlib import Path
from urllib.parse import urljoin

from selenium import webdriver
from selenium.common.exceptions import JavascriptException, TimeoutException
from selenium.webdriver.chrome.options import Options
from selenium.webdriver.support.ui import WebDriverWait


CLICK_BY_TEXT_JS = r"""
const wanted = arguments[0];
const allowPartial = arguments[1];

function normalize(value) {
  return (value || '').replace(/\s+/g, ' ').trim().toLowerCase();
}

function isVisible(element) {
  if (!element) {
    return false;
  }
  const style = window.getComputedStyle(element);
  const rect = element.getBoundingClientRect();
  return style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0;
}

function clickableAncestor(element) {
  let current = element;
  while (current) {
    if (
      current.tagName === 'BUTTON' ||
      current.tagName === 'A' ||
      current.getAttribute('role') === 'button' ||
      current.onclick ||
      current.tabIndex >= 0
    ) {
      return current;
    }
    current = current.parentElement;
  }
  return element;
}

const selectors = [
  'button',
  'a',
  '[role="button"]',
  '[aria-label]',
  'input[type="button"]',
  'input[type="submit"]',
  'label',
  'div',
  'span',
  'p',
  'h1',
  'h2',
  'h3'
];

const target = normalize(wanted);
const nodes = Array.from(document.querySelectorAll(selectors.join(',')));
const exact = [];
const partial = [];

for (const node of nodes) {
  if (!isVisible(node)) {
    continue;
  }
  const values = [
    normalize(node.innerText),
    normalize(node.textContent),
    normalize(node.getAttribute('aria-label')),
    normalize(node.value),
    normalize(node.title)
  ].filter(Boolean);

  if (!values.length) {
    continue;
  }

  if (values.some((value) => value === target)) {
    exact.push(node);
    continue;
  }

  if (allowPartial && values.some((value) => value.includes(target))) {
    partial.push(node);
  }
}

const winner = (exact[0] || partial[0]);
if (!winner) {
  return false;
}

const clickable = clickableAncestor(winner);
clickable.scrollIntoView({ block: 'center', inline: 'center' });
for (const eventName of ['pointerdown', 'mousedown', 'mouseup', 'click']) {
  clickable.dispatchEvent(new MouseEvent(eventName, {
    bubbles: true,
    cancelable: true,
    composed: true,
    view: window,
  }));
}
return true;
"""


TEXT_PRESENT_JS = r"""
const wanted = arguments[0];
const allowPartial = arguments[1];

function normalize(value) {
  return (value || '').replace(/\s+/g, ' ').trim().toLowerCase();
}

function isVisible(element) {
  if (!element) {
    return false;
  }
  const style = window.getComputedStyle(element);
  const rect = element.getBoundingClientRect();
  return style.display !== 'none' && style.visibility !== 'hidden' && rect.width > 0 && rect.height > 0;
}

const target = normalize(wanted);
const nodes = Array.from(document.querySelectorAll('body *'));

for (const node of nodes) {
  if (!isVisible(node)) {
    continue;
  }
  const values = [
    normalize(node.innerText),
    normalize(node.textContent),
    normalize(node.getAttribute && node.getAttribute('aria-label')),
    normalize(node.value),
    normalize(node.title)
  ].filter(Boolean);

  for (const value of values) {
    if (value === target) {
      return true;
    }
    if (allowPartial && value.includes(target)) {
      return true;
    }
  }
}

return false;
"""


BLOB_TO_BASE64_JS = r"""
const done = arguments[0];

fetch(window.location.href)
  .then((response) => response.arrayBuffer())
  .then((buffer) => {
    const bytes = new Uint8Array(buffer);
    const chunkSize = 0x8000;
    let binary = '';
    for (let index = 0; index < bytes.length; index += chunkSize) {
      binary += String.fromCharCode.apply(null, bytes.subarray(index, index + chunkSize));
    }
    done({ ok: true, data: btoa(binary) });
  })
  .catch((error) => done({ ok: false, error: String(error) }));
"""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Verify that the Resume Builder web app can export a PDF by "
            "creating a fresh resume, selecting a free template, and checking "
            "the resulting PDF bytes."
        )
    )
    parser.add_argument(
        "--base-url",
        required=True,
        help="Root URL of the running web app, for example http://127.0.0.1:5000/",
    )
    parser.add_argument(
        "--download-dir",
        help="Directory where exported PDFs should be written. Defaults to a temp folder.",
    )
    parser.add_argument(
        "--template",
        default="Classic",
        help="Visible template name to select before exporting. Defaults to Classic.",
    )
    parser.add_argument(
        "--timeout",
        type=int,
        default=90,
        help="Seconds to wait for each major UI or export step. Defaults to 90.",
    )
    parser.add_argument(
        "--headed",
        action="store_true",
        help="Run Chrome with a visible window instead of headless mode.",
    )
    parser.add_argument(
        "--keep-downloads",
        action="store_true",
        help="Keep the download folder after the run finishes.",
    )
    return parser.parse_args()


def build_url(base_url: str, path: str) -> str:
    return urljoin(base_url.rstrip("/") + "/", path.lstrip("/"))


def create_driver(download_dir: Path, headed: bool) -> webdriver.Chrome:
    options = Options()
    options.add_argument("--window-size=1600,1200")
    options.add_argument("--disable-search-engine-choice-screen")
    options.add_argument("--disable-popup-blocking")
    options.add_argument("--no-first-run")
    options.add_argument("--no-default-browser-check")
    options.add_experimental_option(
        "prefs",
        {
            "download.default_directory": str(download_dir),
            "download.prompt_for_download": False,
            "download.directory_upgrade": True,
            "plugins.always_open_pdf_externally": True,
            "safebrowsing.enabled": True,
        },
    )
    if not headed:
        options.add_argument("--headless=new")

    driver = webdriver.Chrome(options=options)
    driver.set_page_load_timeout(120)
    driver.execute_cdp_cmd(
        "Page.setDownloadBehavior",
        {"behavior": "allow", "downloadPath": str(download_dir)},
    )
    return driver


def text_present(driver: webdriver.Chrome, text: str, partial: bool = False) -> bool:
    try:
        return bool(driver.execute_script(TEXT_PRESENT_JS, text, partial))
    except JavascriptException:
        return False


def wait_for_text(
    driver: webdriver.Chrome,
    text: str,
    timeout: int,
    *,
    partial: bool = False,
) -> None:
    WebDriverWait(driver, timeout).until(lambda current: text_present(current, text, partial))


def wait_for_text_to_disappear(
    driver: webdriver.Chrome,
    text: str,
    timeout: int,
    *,
    partial: bool = False,
) -> None:
    WebDriverWait(driver, timeout).until(
        lambda current: not text_present(current, text, partial)
    )


def click_text(
    driver: webdriver.Chrome,
    text: str,
    timeout: int,
    *,
    partial: bool = False,
) -> None:
    WebDriverWait(driver, timeout).until(
        lambda current: bool(current.execute_script(CLICK_BY_TEXT_JS, text, partial))
    )


def wait_for_url(driver: webdriver.Chrome, pattern: str, timeout: int) -> None:
    regex = re.compile(pattern)
    WebDriverWait(driver, timeout).until(lambda current: regex.search(current.current_url))


def ensure_dashboard(driver: webdriver.Chrome, base_url: str, timeout: int) -> None:
    driver.get(build_url(base_url, "/dashboard"))

    if text_present(driver, "Skip"):
        click_text(driver, "Skip", timeout)

    if text_present(driver, "Continue to Dashboard (Web Preview)"):
        click_text(driver, "Continue to Dashboard (Web Preview)", timeout)

    wait_for_text(driver, "Resumes", timeout)


def create_resume_and_select_template(
    driver: webdriver.Chrome,
    base_url: str,
    template_name: str,
    timeout: int,
) -> str:
    click_text(driver, "Resumes", timeout)
    wait_for_text(driver, "New Resume", timeout)
    click_text(driver, "New Resume", timeout)
    wait_for_url(driver, r"/templates/([^/?]+)", timeout)

    match = re.search(r"/templates/([^/?]+)", driver.current_url)
    if not match:
        raise RuntimeError(f"Could not extract resume id from URL: {driver.current_url}")
    resume_id = match.group(1)

    click_text(driver, template_name, timeout)
    click_text(driver, "Apply & Start Editing", timeout)
    wait_for_url(driver, rf"/editor/{re.escape(resume_id)}", timeout)

    driver.get(build_url(base_url, f"/preview/{resume_id}"))
    wait_for_url(driver, rf"/preview/{re.escape(resume_id)}", timeout)
    wait_for_text(driver, "Export Resume", timeout)

    try:
        wait_for_text_to_disappear(driver, "Generating PDF...", timeout)
    except TimeoutException:
        pass

    return resume_id


def fetch_blob_pdf(driver: webdriver.Chrome, target_path: Path) -> Path:
    result = driver.execute_async_script(BLOB_TO_BASE64_JS)
    if not isinstance(result, dict) or not result.get("ok"):
        raise RuntimeError(f"Could not read blob PDF bytes: {result}")

    target_path.write_bytes(base64.b64decode(result["data"]))
    return target_path


def wait_for_pdf_artifact(
    driver: webdriver.Chrome,
    download_dir: Path,
    timeout: int,
    existing_handles: set[str],
    existing_pdfs: set[Path],
) -> Path:
    deadline = time.time() + timeout

    while time.time() < deadline:
        current_handles = set(driver.window_handles)
        new_handles = current_handles - existing_handles
        if new_handles:
            new_handle = next(iter(new_handles))
            driver.switch_to.window(new_handle)
            current_url = driver.current_url
            if current_url.startswith("blob:"):
                return fetch_blob_pdf(driver, download_dir / "resume-export-from-blob.pdf")
            if current_url.startswith("data:application/pdf;base64,"):
                encoded = current_url.split(",", 1)[1]
                target = download_dir / "resume-export-from-data-uri.pdf"
                target.write_bytes(base64.b64decode(encoded))
                return target

        for pdf_path in sorted(download_dir.glob("*.pdf")):
            if pdf_path in existing_pdfs:
                continue
            if pdf_path.with_suffix(pdf_path.suffix + ".crdownload").exists():
                continue
            if pdf_path.stat().st_size == 0:
                continue
            return pdf_path

        time.sleep(0.5)

    raise TimeoutError(f"Timed out waiting for a PDF export in {download_dir}")


def export_pdf(driver: webdriver.Chrome, download_dir: Path, timeout: int) -> Path:
    existing_handles = set(driver.window_handles)
    existing_pdfs = set(download_dir.glob("*.pdf"))

    click_text(driver, "Export Resume", timeout)
    wait_for_text(driver, "Choose your file format.", timeout)
    click_text(driver, "PDF", timeout)

    try:
        wait_for_text(driver, "Print preview opened from a dedicated PDF tab.", 5)
    except TimeoutException:
        pass

    return wait_for_pdf_artifact(
        driver,
        download_dir,
        timeout,
        existing_handles,
        existing_pdfs,
    )


def validate_pdf(pdf_path: Path) -> dict[str, int]:
    data = pdf_path.read_bytes()
    if not data.startswith(b"%PDF-"):
        raise AssertionError(f"{pdf_path.name} does not start with a PDF header")

    if b"%%EOF" not in data[-2048:]:
        raise AssertionError(f"{pdf_path.name} is missing a PDF EOF trailer")

    if b"/Catalog" not in data:
        raise AssertionError(f"{pdf_path.name} is missing the PDF catalog object")

    page_markers = data.count(b"/Type /Page")
    if page_markers < 1:
        raise AssertionError(f"{pdf_path.name} does not appear to contain any pages")

    if len(data) < 1024:
        raise AssertionError(f"{pdf_path.name} is unexpectedly small: {len(data)} bytes")

    return {
        "bytes": len(data),
        "pages": page_markers,
    }


def main() -> int:
    args = parse_args()
    temp_dir_created = False

    if args.download_dir:
        download_dir = Path(args.download_dir).expanduser().resolve()
        download_dir.mkdir(parents=True, exist_ok=True)
    else:
        download_dir = Path(tempfile.mkdtemp(prefix="resume-pdf-export-"))
        temp_dir_created = True

    driver: webdriver.Chrome | None = None
    try:
        driver = create_driver(download_dir, headed=args.headed)
        ensure_dashboard(driver, args.base_url, args.timeout)
        resume_id = create_resume_and_select_template(
            driver,
            args.base_url,
            args.template,
            args.timeout,
        )
        pdf_path = export_pdf(driver, download_dir, args.timeout)
        metrics = validate_pdf(pdf_path)

        print("PDF export verification passed")
        print(f"Resume ID: {resume_id}")
        print(f"PDF path: {pdf_path}")
        print(f"PDF size: {metrics['bytes']} bytes")
        print(f"Detected page markers: {metrics['pages']}")
        return 0
    except Exception as error:  # noqa: BLE001
        print(f"PDF export verification failed: {error}", file=sys.stderr)
        return 1
    finally:
        if driver is not None:
            driver.quit()
        if temp_dir_created and not args.keep_downloads:
            shutil.rmtree(download_dir, ignore_errors=True)


if __name__ == "__main__":
    raise SystemExit(main())