module.exports = {
  name: 'user-management',
  preset: '../../jest.config.js',
  coverageDirectory: '../../coverage/apps/user-management',
  snapshotSerializers: [
    'jest-preset-angular/AngularSnapshotSerializer.js',
    'jest-preset-angular/HTMLCommentSerializer.js'
  ]
};
