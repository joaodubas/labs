module.exports = {
  autodiscover: true,
  endpoint: process.env.RENOVATE_ENDPOINT || 'https://gitea.dubas.dev/api/v1',
  onboardingConfig: {
    extends: ['config:base'],
  },
  platform: "gitea",
  repositoryCache: "enabled",
};
