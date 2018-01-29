jsnext    = require('@luna-lang/jsnext')


var math = 'basegl.Math'

var operatorMap = {
  '=='  : `${math}.eq`,
  '===' : `${math}.eq`,
  '!='  : `${math}.neq`,
  '!==' : `${math}.neq`,
  '<'   : `${math}.lt`,
  '<='  : `${math}.lte`,
  '>'   : `${math}.gt`,
  '>='  : `${math}.gte`,
  '<<'  : `${math}.lshift`,
  '>>'  : `${math}.rshift`,
  '>>>' : `${math}.rshift2`,
  '+'   : `${math}.add`,
  '-'   : `${math}.sub`,
  '*'   : `${math}.mul`,
  '/'   : `${math}.div`,
  '%'   : `${math}.mod`,
  '||'  : `${math}.or`,
  '&&'  : `${math}.and`
}

var jsnextRules = {
  'basegl.math': [ jsnext.overloadOperators((n) => operatorMap[n])
                 , jsnext.replaceQualifiedAccessors('Math', math)
                 ]
}


module.exports = function(source) {
  this.value = source;

  // var json = JSON.stringify(source)
  //   .replace(/\u2028/g, '\\u2028')
  //   .replace(/\u2029/g, '\\u2029');

  out = jsnext.preprocessModule('unknown.js', jsnextRules, source);
  // console.log(out);
  // console.log(source);
  return out;
}
