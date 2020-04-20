const { environment } = require('@rails/webpacker')
const webpack = require('webpack')

/* aggiunto, vedi https://blog.grillwork.io/create-a-ruby-on-rails-5-1-application-with-webpack-react-16-and-react-router-e2c16d267f73 */
module: {
  rules: [
    {
      test: /\.js(\.erb)?$/,
      exclude: /node_modules/,
      loader: 'babel-loader',
      options: {
        presets: [
          ['env', { modules: false }]
        ]
      }
    },
  ]
}

environment.loaders.get('sass').use.splice(-1, 0, {
  loader: 'resolve-url-loader',
  options: {
    attempts: 1
  }
});

/* fine aggiunta */

/* includo jquery */
environment.plugins.prepend(
  'Provide',
  new webpack.ProvidePlugin({
    $: 'jquery',
    jQuery: 'jquery',
    jquery: 'jquery',
    'window.jQuery': 'jquery',
    Popper: ['popper.js', 'default']
  })
)


module.exports = environment
