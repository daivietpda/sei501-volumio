'use strict';

var libQ = require('kew');
var fs = require('fs-extra');

module.exports = ControllerMyVolumio;

function ControllerMyVolumio(context) {
  this.context = context;
  this.commandRouter = context.coreCommand;
  this.logger = context.logger;
  this.tokenFile = '/data/configuration/system_controller/my_volumio/token.json';
}

ControllerMyVolumio.prototype.onVolumioStart = function () { return libQ.resolve(); };
ControllerMyVolumio.prototype.onStart = function () { return libQ.resolve('OK'); };
ControllerMyVolumio.prototype.onStop = function () { return libQ.resolve('OK'); };

ControllerMyVolumio.prototype.readToken = function () {
  try {
    var data = fs.readJsonSync(this.tokenFile);
    return data && data.token ? data.token : '';
  } catch (error) {
    return '';
  }
};

ControllerMyVolumio.prototype.decodeToken = function (token) {
  try {
    var payload = token.split('.')[1].replace(/-/g, '+').replace(/_/g, '/');
    while (payload.length % 4) payload += '=';
    return JSON.parse(Buffer.from(payload, 'base64').toString('utf8'));
  } catch (error) {
    return {};
  }
};

ControllerMyVolumio.prototype.getMyVolumioToken = function () {
  var token = this.readToken();
  return libQ.resolve({'tokenAvailable': Boolean(token), 'token': token});
};

ControllerMyVolumio.prototype.setMyVolumioToken = function (data) {
  var token = data && data.token ? data.token : '';
  try {
    fs.ensureDirSync('/data/configuration/system_controller/my_volumio');
    fs.writeJsonSync(this.tokenFile, {'token': token, 'updatedAt': new Date().toISOString()}, {'mode': 384});
    return libQ.resolve(token);
  } catch (error) {
    this.logger.error('MyVolumio compatibility token could not be saved: ' + error);
    return libQ.reject(error);
  }
};

ControllerMyVolumio.prototype.getMyVolumioStatus = function () {
  var token = this.readToken();
  var payload = this.decodeToken(token);
  var expired = payload.exp && payload.exp <= Math.floor(Date.now() / 1000);
  return libQ.resolve({
    'loggedIn': Boolean(token) && !expired,
    'uid': payload.uid || payload.user_id || payload.sub || ''
  });
};

ControllerMyVolumio.prototype.myVolumioLogout = function () {
  try { fs.removeSync(this.tokenFile); } catch (error) {}
  return libQ.resolve('OK');
};

ControllerMyVolumio.prototype.retreiveBackendEventStates = function () { return libQ.resolve({}); };
ControllerMyVolumio.prototype.getAutoUpdateCheckEnabled = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.getAutoUpdateEnabled = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.detectVolumioHardware = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.showActivationCode = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.checkDeviceCode = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.getDeviceActivationStatus = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.enableMyVolumioDevice = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.disableMyVolumioDevice = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.deleteMyVolumioDevice = function () { return libQ.resolve(false); };
ControllerMyVolumio.prototype.saveCloudItem = function () { return libQ.reject(new Error('Cloud playlists are not available on this community image')); };
ControllerMyVolumio.prototype.deleteCloudPlaylist = function () { return libQ.reject(new Error('Cloud playlists are not available on this community image')); };
