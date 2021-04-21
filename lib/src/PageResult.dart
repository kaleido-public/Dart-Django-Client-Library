import './Model.dart';

class PageResult<T extends Model> {
  double page = 0;
  double limit = 0;
  double total = 0;
  String previous = "";
  String next = "";
  List<T> objects = [];
}