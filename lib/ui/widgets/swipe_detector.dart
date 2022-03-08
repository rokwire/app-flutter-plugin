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

class SwipeConfiguration {
  //Vertical swipe configuration options
  final double verticalSwipeMaxWidthThreshold;
  final double verticalSwipeMinDisplacement;
  final double verticalSwipeMinVelocity;

  //Horizontal swipe configuration options
  final double horizontalSwipeMaxHeightThreshold;
  final double horizontalSwipeMinDisplacement;
  final double horizontalSwipeMinVelocity;

  const SwipeConfiguration({
    this.verticalSwipeMaxWidthThreshold = 50.0,
    this.verticalSwipeMinDisplacement = 100.0,
    this.verticalSwipeMinVelocity = 300.0,
    this.horizontalSwipeMaxHeightThreshold = 50.0,
    this.horizontalSwipeMinDisplacement = 100.0,
    this.horizontalSwipeMinVelocity = 300.0,
  });
}

class SwipeDetector extends StatelessWidget {
  final Widget child;
  final Function()? onSwipeUp;
  final Function()? onSwipeDown;
  final Function()? onSwipeLeft;
  final Function()? onSwipeRight;
  final SwipeConfiguration swipeConfiguration;

  const SwipeDetector(
      {Key? key, required this.child,
      this.onSwipeUp,
      this.onSwipeDown,
      this.onSwipeLeft,
      this.onSwipeRight,
      this.swipeConfiguration = const SwipeConfiguration()
    }): super(key: key);

  @override
  Widget build(BuildContext context) {
    //Vertical drag details
    late DragStartDetails startVerticalDragDetails;
    late DragUpdateDetails updateVerticalDragDetails;

    //Horizontal drag details
    late DragStartDetails startHorizontalDragDetails;
    late DragUpdateDetails updateHorizontalDragDetails;

    return GestureDetector(
      child: child,
      excludeFromSemantics: true,
      onVerticalDragStart: (dragDetails) {
        startVerticalDragDetails = dragDetails;
      },
      onVerticalDragUpdate: (dragDetails) {
        updateVerticalDragDetails = dragDetails;
      },
      onVerticalDragEnd: (endDetails) {
        double dx = updateVerticalDragDetails.globalPosition.dx -
            startVerticalDragDetails.globalPosition.dx;
        double dy = updateVerticalDragDetails.globalPosition.dy -
            startVerticalDragDetails.globalPosition.dy;
        double velocity = endDetails.primaryVelocity!;

        //Convert values to be positive
        if (dx < 0) dx = -dx;
        if (dy < 0) dy = -dy;
        double positiveVelocity = velocity < 0 ? -velocity : velocity;

        if (dx > swipeConfiguration.verticalSwipeMaxWidthThreshold) return;
        if (dy < swipeConfiguration.verticalSwipeMinDisplacement) return;
        if (positiveVelocity < swipeConfiguration.verticalSwipeMinVelocity) {
          return;
        }

        if (velocity < 0) {
          //Swipe Up
          if (onSwipeUp != null) {
            onSwipeUp!();
          }
        } else {
          //Swipe Down
          if (onSwipeDown != null) {
            onSwipeDown!();
          }
        }
      },
      onHorizontalDragStart: (dragDetails) {
        startHorizontalDragDetails = dragDetails;
      },
      onHorizontalDragUpdate: (dragDetails) {
        updateHorizontalDragDetails = dragDetails;
      },
      onHorizontalDragEnd: (endDetails) {
        double dx = updateHorizontalDragDetails.globalPosition.dx -
            startHorizontalDragDetails.globalPosition.dx;
        double dy = updateHorizontalDragDetails.globalPosition.dy -
            startHorizontalDragDetails.globalPosition.dy;
        double velocity = endDetails.primaryVelocity!;

        if (dx < 0) dx = -dx;
        if (dy < 0) dy = -dy;
        double positiveVelocity = velocity < 0 ? -velocity : velocity;

        debugPrint("$dx $dy $velocity $positiveVelocity");

        if (dx < swipeConfiguration.horizontalSwipeMinDisplacement) return;
        if (dy > swipeConfiguration.horizontalSwipeMaxHeightThreshold) return;
        if (positiveVelocity < swipeConfiguration.horizontalSwipeMinVelocity) {
          return;
        }

        if (velocity < 0) {
          //Swipe Up
          if (onSwipeLeft != null) {
            onSwipeLeft!();
          }
        } else {
          //Swipe Down
          if (onSwipeRight != null) {
            onSwipeRight!();
          }
        }
      },
    );
  }
}
