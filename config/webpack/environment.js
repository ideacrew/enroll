const { environment } = require('@rails/webpacker')
const babelConfig = require('../../babel.config.rb.js')
const erb = require('./loaders/erb')
const webpack = require('webpack')

environment.plugins.append('Provide', new webpack.ProvidePlugin({
  $: 'jquery',
  jQuery: 'jquery',
  Popper: ['popper.js', 'default']
}))
environment.loaders.append('ruby', {
  test: /\.rb$/,
  use: {
    loader: 'babel-loader',
    options: babelConfig
  }
})
environment.loaders.prepend('erb', erb)
module.exports = environment
