/*
 * Copyright 2020 Board of Trustees of the University of Illinois.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:flutter/material.dart';

enum TriangleHorzDirection { leftToRight, rightToLeft }
enum TriangleVertDirection { topToBottom, bottomToTop }

class TrianglePainter extends CustomPainter {
  final Color? painterColor;
  final TriangleHorzDirection horzDir;
  final TriangleVertDirection vertDir;

  TrianglePainter({this.painterColor,
    this.horzDir = TriangleHorzDirection.rightToLeft,
    this.vertDir = TriangleVertDirection.topToBottom,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    paint.color = painterColor!;
    // create a path
    var path = Path();
    if (vertDir == TriangleVertDirection.topToBottom) {
      if (horzDir == TriangleHorzDirection.rightToLeft) {
        path.lineTo(0, size.height);
        path.lineTo(size.width, size.height);
      }
      else if (horzDir == TriangleHorzDirection.leftToRight) {
        path.moveTo(0, size.height);
        path.lineTo(size.width, 0);
        path.lineTo(size.width, size.height);
      }
    }
    else if (vertDir == TriangleVertDirection.bottomToTop) {
      if (horzDir == TriangleHorzDirection.leftToRight) {
        path.moveTo(size.width, size.height);
        path.lineTo(size.width, 0);
        path.lineTo(0, 0);
      }
      else if (horzDir == TriangleHorzDirection.rightToLeft) {
        path.moveTo(size.width, 0);
        path.lineTo(0, size.height);
        path.lineTo(0, 0);
      }
    }
    
    // close the path to form a bounded shape
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
