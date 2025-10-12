const mongoose = require("mongoose");

const resumeSchema = new mongoose.Schema(
	{
		// Note: For now we store whatever the JWT carries (number from in-memory users).
		// Later, if users move fully to Mongo, switch to { type: mongoose.Schema.Types.ObjectId, ref: 'User' }.
		userId: { type: mongoose.Schema.Types.Mixed, required: true, index: true },

		title: { type: String, trim: true },
		template: { type: String, trim: true },

		personalInfo: { type: mongoose.Schema.Types.Mixed },
		summary: { type: String },

		workExperience: { type: [mongoose.Schema.Types.Mixed], default: [] },
		education: { type: [mongoose.Schema.Types.Mixed], default: [] },
		skills: { type: [mongoose.Schema.Types.Mixed], default: [] },

		// Extra flexible payload per template
		data: { type: mongoose.Schema.Types.Mixed },
	},
	{ timestamps: true }
);

resumeSchema.index({ userId: 1, updatedAt: -1 });

module.exports = mongoose.model("Resume", resumeSchema);
