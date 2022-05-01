module.exports = {
  autodiscover: true,
  endpoint: 'https://gitea.dubas.dev/api/v1',
  onboardingConfig: {
    extends: ['config:base'],
  },
  platform: "gitea",
  repositoryCache: "enabled",
};
