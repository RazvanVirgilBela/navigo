import 'dart:math';
import 'package:ml_linalg/linalg.dart';

class KMeans {
  final int k;
  final int maxIterations;
  final List<Vector> data;
  List<Vector> centroids = [];

  KMeans(this.data, this.k, {this.maxIterations = 100}) {
    _initializeCentroids();
    _runKMeans();
  }

  void _initializeCentroids() {
    final random = Random();
    centroids = List.generate(k, (_) => data[random.nextInt(data.length)]);
  }

  void _runKMeans() {
    for (var i = 0; i < maxIterations; i++) {
      final clusters = List.generate(k, (_) => <Vector>[]);
      for (final point in data) {
        final centroidIndex = _closestCentroidIndex(point);
        clusters[centroidIndex].add(point);
      }
      final newCentroids = List<Vector>.generate(k, (index) {
        if (clusters[index].isEmpty) {
          return centroids[index];
        }
        final sum = clusters[index].reduce((a, b) => a + b);
        return sum / clusters[index].length.toDouble();
      });

      if (_hasConverged(newCentroids)) {
        break;
      }
      centroids = newCentroids;
    }
  }

  int _closestCentroidIndex(Vector point) {
    var minDistance = double.infinity;
    var minIndex = 0;
    for (var i = 0; i < centroids.length; i++) {
      final distance = (point - centroids[i]).norm();
      if (distance < minDistance) {
        minDistance = distance;
        minIndex = i;
      }
    }
    return minIndex;
  }

  bool _hasConverged(List<Vector> newCentroids) {
    for (var i = 0; i < centroids.length; i++) {
      if ((centroids[i] - newCentroids[i]).norm() > 1e-6) {
        return false;
      }
    }
    return true;
  }
}
