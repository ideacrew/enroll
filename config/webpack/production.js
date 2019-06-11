process.env.NODE_ENV = process.env.NODE_ENV || 'production'

const environment = require('./environment');
const webpack = require('webpack');
const ngw = require( "@ngtools/webpack" );
const path = require('path');

var webpack_environment = environment.toWebpackConfig()

webpack_environment.entry.incremental_angular = "./app/javascript/incremental_angular/main.prod.ts";

webpack_environment.module.rules.push({
  	test: /\.html$/,
        loader: 'html-loader'
})

webpack_environment.module.rules.push({
  test: /(?:\.ngfactory\.js|\.ngstyle\.js|\.ts)$/,
  loader: '@ngtools/webpack'
})

webpack_environment.plugins.push(
		new ngw.AngularCompilerPlugin({
			tsConfigPath: "./app/javascript/incremental_angular/tsconfig.prod.json",
			entryModule: "./app/javascript/incremental_angular/app/app.module#AppModule",
		})
)
webpack_environment.plugins.push(
		new webpack.ProvidePlugin({
			jQuery: 'jquery',
			$: 'jquery',
			jquery: 'jquery'
		})
)

webpack_environment.externals = {
  jquery: 'jQuery'
};

module.exports = webpack_environment;
