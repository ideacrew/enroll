function toCurrency(element) {
  element.value = element.value.replace(/[^0-9.]/g, '').replace(/(\..*)\./g, '$1')
}