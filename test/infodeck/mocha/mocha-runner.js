mocha.setup('bdd');
window.expect = chai.expect;
window.assert = chai.assert;

$(function(){

  mocha.checkLeaks();
  mocha.run();
});
