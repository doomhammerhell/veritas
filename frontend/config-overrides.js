// Webpack overrides for starknet.js Node polyfills
module.exports = function override(config) {
  config.resolve.fallback = {
    ...config.resolve.fallback,
    util: require.resolve('util/'),
    stream: false,
    crypto: false,
    http: false,
    https: false,
    os: false,
    url: false,
    assert: false,
    buffer: false,
    process: false,
  };
  return config;
};
