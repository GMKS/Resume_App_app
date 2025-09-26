# Use official Node.js LTS image
FROM node:20-alpine

WORKDIR /app

# Install dependencies first (better layer caching)
COPY package*.json ./
RUN npm ci --only=production

# Copy source
COPY server.js ./

# Expose port
EXPOSE 3000

# Use env PORT if provided by platform, default 3000
ENV PORT=3000

CMD ["node", "server.js"]
