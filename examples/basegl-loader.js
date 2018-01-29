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
  out = jsnext.preprocessModule('unknown.js', jsnextRules, source, {library: 'basegl', call: 'expr', defaultExts: ['basegl.math']});
  return out;
}
