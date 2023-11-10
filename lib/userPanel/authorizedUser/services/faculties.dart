
class Faculties {
  static List<String> list = [
    "Biotechnology & Life Sciences",
    "Computing & IT",
    "Engineering",
    "Fashion Design",
    "Business",
    "Graphic Design",
    "Health Sciences",
    "Hospitality & Culinary Arts",
    "Interior Design",
    "English Language Programs",
    "Multimedia Design",
    "Mass Communication",
    "Pre-University Programmes",
    "Social Science",
    "Postgraduate Studies",
  ];

  static List<String> getFaculties() {
    return list;
  }

  static void addFaculty(String faculty) {
    list.add(faculty);
  }
}
