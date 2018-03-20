/* global MLSearchController */
(function() {
  'use strict';

  angular.module('app.search')
    .controller('SearchCtrl', SearchCtrl);

  SearchCtrl.$inject = ['$scope', '$location', 'MLSearchFactory', 'MLRest'];

  // inherit from MLSearchController
  var superCtrl = MLSearchController.prototype;
  SearchCtrl.prototype = Object.create(superCtrl);
  
  


  function SearchCtrl($scope, $location, searchFactory, mlRest) {
    var ctrl = this;

    superCtrl.constructor.call(ctrl, $scope, $location, searchFactory.newContext(), mlRest);

    ctrl.init();

    ctrl.setSnippet = function(type) {
      ctrl.mlSearch.setSnippet(type);
      ctrl.search();
    };

    ctrl.setSort = function(type) {
      ctrl.mlSearch.setSort(type);
      ctrl.search();
    };

    ctrl.loadCustomer = function() {
      console.log("loading sample customer file");
      $scope.uploadCust="true";
      var settingsGET = {
        method:'PUT'
      };
      mlRest.extension('/loadSampleData',settingsGET).then(function(response)  {
        $scope.uploadCust=false
      })
    };

    ctrl.loadMSTRCube = function() {
      console.log("loading sample customer file");
      $scope.loadCube="true";
      var settingsGET = {
        method:'PUT'
      };
      mlRest.extension('/loadMSTRCube',settingsGET).then(function(response)  {
        $scope.loadCube=false
      })
    };
 

    function listFromOperator(operatorArray, operatorType) {
      return (_.filter(
        operatorArray,
        function(val) {
          return val && val.state && val.state[0] && val.state[0][operatorType];
        }
      )[0] || { state: []}).state.map(function(state) {
        return state.name;
      });
    }


    ctrl.mlSearch.getStoredOptions().then(function(data) {
      ctrl.sortList = listFromOperator(data.options.operator, 'sort-order');
      ctrl.snippetList = listFromOperator(data.options.operator, 'transform-results');
    });

  }
}());
