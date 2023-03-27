// babel.config.rb.js
module.exports = {
    presets: [
      [
        "@babel/preset-env",
        {
          targets: {
            node: "current",
          },
        },
      ],
    ],
    plugins: [
      "@babel/plugin-proposal-function-sent",
      "@babel/plugin-proposal-throw-expressions",
    ],
    ignore: [/node_modules/],
  };