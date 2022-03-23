int compareVersion(String version1, String version2) {
  final ver1 = version1.split(".").map((e) => int.parse(e)).toList();
  final ver2 = version2.split(".").map((e) => int.parse(e)).toList();

  var i = 0;
  while (i < ver1.length) {
    final result = ver1[i] - ver2[i];
    if (result != 0) {
      return result;
    }
    i++;
  }

  return 0;
}
