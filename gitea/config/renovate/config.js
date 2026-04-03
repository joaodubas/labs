module.exports = {
	autodiscover: true,
	endpoint: 'https://gitea.dubas.dev/api/v1',
	onboardingConfig: {
		extends: ['config:recommended'],
	},
	platform: "gitea",
	repositoryCache: "enabled",
};
