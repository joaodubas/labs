module.exports = {
	autodiscover: true,
	endpoint: process.env.RENOVATE_GITEA_API || 'http://git:3000/api/v1',
	onboardingConfig: {
		extends: ['config:recommended'],
	},
	platform: "gitea",
	repositoryCache: "enabled",
};
