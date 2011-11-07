Set the export attribute for variables.
{[Spec]}[http://pubs.opengroup.org/onlinepubs/9699919799/utilities/V3_chap02.html#tag_18_22]

(key, value=nil)
--
  var = key.kind_of?(Variable) ? key : Variable.new(self, key)
  var.export value
