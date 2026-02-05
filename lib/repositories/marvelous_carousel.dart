import 'dart:math';
import 'package:flutter/material.dart';

/// A widget for creating a vertical wall calendar carousel.
class MarvelousCarousel extends StatefulWidget {
  final List<Widget> children;
  final ValueChanged<int>? onPageChanged;
  final double margin;
  final Duration animationDuration;
  final bool enablePullToRefresh;
  final Future<void> Function()? onRefresh;
  final double refreshTriggerThreshold;

  const MarvelousCarousel({
    required this.children,
    this.onPageChanged,
    this.margin = 0,
    this.animationDuration = const Duration(milliseconds: 300),
    this.enablePullToRefresh = false,
    this.onRefresh,
    this.refreshTriggerThreshold = 120.0,
    super.key,
  });

  @override
  MarvelousCarouselState createState() => MarvelousCarouselState();
}

class MarvelousCarouselState extends State<MarvelousCarousel> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentPage = 0.0;
  int _activeIndex = 0;
  Size _pagerSize = Size.zero;
  double _dragProgress = 0.0;
  bool _isAnimating = false;
  
  // Refresh logic
  double _pullOffset = 0.0; // How much the card is pulled down
  bool _isRefreshing = false;
  
  // For animation
  double _animationStartPage = 0.0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.animationDuration, 
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToPage(int pageIndex) {
    if (_isAnimating) return;
    
    final targetPage = pageIndex.toDouble();
    final startPage = _currentPage;
    final distance = (targetPage - startPage).abs();
    
    _isAnimating = true;
    _animationStartPage = startPage;
    
    final animation = Tween<double>(
      begin: 0,
      end: distance,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));
    
    animation.addListener(() {
      setState(() {
        if (targetPage > startPage) {
          _currentPage = _animationStartPage + animation.value;
        } else {
          _currentPage = _animationStartPage - animation.value;
        }
        _activeIndex = _currentPage.round();
        _dragProgress = (_currentPage - _currentPage.floor()).abs();
      });
    });
    
    _controller.forward(from: 0).then((_) {
      _controller.reset();
      _isAnimating = false;
      _currentPage = targetPage;
      _activeIndex = targetPage.round();
      _dragProgress = 0.0;
      widget.onPageChanged?.call(_activeIndex);
    });
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    if (_isAnimating || _isRefreshing) return;
    
    final dragDelta = details.primaryDelta ?? 0;
    
    // ===== PULL-TO-REFRESH FROM TOP =====
    if (widget.enablePullToRefresh && _currentPage == 0) {
      // Pulling DOWN (dragDelta > 0) from top of first card
      if (dragDelta > 0) {
        // Add resistance - harder to pull as we go further
        double resistance = 1.0;
        if (_pullOffset > widget.refreshTriggerThreshold * 0.5) {
          resistance = 0.7;
        }
        if (_pullOffset > widget.refreshTriggerThreshold * 0.8) {
          resistance = 0.4;
        }
        
        setState(() {
          _pullOffset = min(
            _pullOffset + (dragDelta * resistance),
            widget.refreshTriggerThreshold * 1.5, // Allow overshoot
          );
        });
        return; // Don't process normal scrolling when pulling to refresh
      }
      // Pulling UP (dragDelta < 0) - can scroll up normally
    }
    
    // ===== NORMAL SCROLLING =====
    // Only allow normal scrolling if we're not pulling to refresh
    if (_pullOffset == 0 || dragDelta < 0) {
      setState(() {
        // Calculate new page position
        double newPage = _currentPage - (dragDelta / _pagerSize.height);
        
        // Clamp between 0 and max pages
        newPage = newPage.clamp(0, widget.children.length - 1);
        
        // If we're at top and scrolling up, reduce pull offset first
        if (_currentPage == 0 && dragDelta < 0 && _pullOffset > 0) {
          _pullOffset = max(0, _pullOffset + dragDelta);
        } else if (!(_currentPage == widget.children.length - 1 && dragDelta > 0)) {
          _currentPage = newPage;
        }
        
        _activeIndex = _currentPage.round();
        _dragProgress = (_currentPage - _currentPage.floor()).abs();
        
        // If we scroll away from top, reset pull offset
        if (_currentPage > 0.1) {
          _pullOffset = 0.0;
        }
      });
    }
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_isAnimating) return;
    
    // ===== PULL-TO-REFRESH RELEASE =====
    if (_pullOffset > 0) {
      // Check if pulled enough (50% of threshold)
      if (_pullOffset >= widget.refreshTriggerThreshold * 0.5 && !_isRefreshing) {
        _triggerRefresh();
      } else {
        // Not pulled enough - animate back
        _animatePullBack();
      }
      return;
    }
    
    // ===== NORMAL SCROLL END =====
    _handleNormalScrollEnd(details);
  }

  void _handleNormalScrollEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final dragFraction = _dragProgress;
    final currentFloor = _currentPage.floor();
    
    int targetPage;
    
    if (velocity.abs() > 300) {
      targetPage = velocity > 0 ? currentFloor : min(widget.children.length - 1, currentFloor + 1);
    } else if (dragFraction > 0.15) {
      targetPage = min(widget.children.length - 1, currentFloor + 1);
    } else {
      targetPage = currentFloor;
    }
    
    targetPage = max(0, min(widget.children.length - 1, targetPage));
    
    if (targetPage != _currentPage.round() || dragFraction > 0) {
      _goToPage(targetPage);
    }
  }

  // ===== REFRESH ANIMATIONS =====
  void _animatePullBack() {
    final animation = Tween<double>(begin: _pullOffset, end: 0.0)
      .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
    
    animation.addListener(() {
      setState(() {
        _pullOffset = animation.value;
      });
    });
    
    _controller.forward(from: 0).then((_) {
      _controller.reset();
    });
  }

  void _animateRefreshComplete() {
    final animation = Tween<double>(begin: _pullOffset, end: 0.0)
      .animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut,
      ));
    
    animation.addListener(() {
      setState(() {
        _pullOffset = animation.value;
      });
    });
    
    _controller.forward(from: 0).then((_) {
      _controller.reset();
      setState(() {
        _isRefreshing = false;
      });
    });
  }

  Future<void> _triggerRefresh() async {
    if (_isRefreshing || widget.onRefresh == null) return;
    
    setState(() {
      _isRefreshing = true;
    });
    
    try {
      await widget.onRefresh!();
    } catch (e) {
      print('Refresh error: $e');
    } finally {
      // Wait a bit then animate back up
      await Future.delayed(Duration(milliseconds: 500));
      if (mounted) {
        _animateRefreshComplete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _pagerSize = constraints.biggest;
        final currentIndex = _currentPage.floor();
        final nextIndex = currentIndex + 1;
        
        return Stack(
          clipBehavior: Clip.none, // IMPORTANT: Allow overflow
          children: [
            // Background refresh indicator area (TOP of screen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: widget.refreshTriggerThreshold,
              child: Container(
                color: Colors.transparent,
                child: Center(
                  child: _buildRefreshIndicator(),
                ),
              ),
            ),
            
            // Main carousel content
            Positioned.fill(
              child: Transform.translate(
                offset: Offset(0, _pullOffset), // Move the WHOLE content down
                child: GestureDetector(
                  onVerticalDragUpdate: _handleDragUpdate,
                  onVerticalDragEnd: _handleDragEnd,
                  behavior: HitTestBehavior.opaque,
                  child: Stack(
                    clipBehavior: Clip.none, // Allow overflow here too
                    children: [
                      // Next page (if exists)
                      if (nextIndex < widget.children.length && _dragProgress > 0.01)
                        Positioned.fill(
                          child: _buildPage(nextIndex, isNext: true),
                        ),
                      
                      // Current page
                      Positioned.fill(
                        child: _buildPage(currentIndex, isCurrent: true),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRefreshIndicator() {
    final progress = _pullOffset / widget.refreshTriggerThreshold;
    
    if (_isRefreshing) {
      // Show spinner when refreshing
      return SizedBox(
        width: 30,
        height: 30,
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          strokeWidth: 2.5,
        ),
      );
    } else if (_pullOffset > 10) {
      // Show pull indicator when pulling
      return Transform.rotate(
        angle: pi * 2 * progress.clamp(0, 1),
        child: Icon(
          Icons.refresh,
          size: 30,
          color: Colors.blue.withValues(alpha:  0.8 * progress.clamp(0, 1)),
        ),
      );
    } else {
      return SizedBox.shrink();
    }
  }

  Widget _buildPage(int index, {bool isCurrent = false, bool isNext = false}) {
    final pageDiff = _currentPage - index;
    final dragAmount = pageDiff.abs();
    
    double translateY = 0.0;
    double rotateX = 0.0;
    
    if (isCurrent) {
      translateY = -dragAmount * _pagerSize.height;
      rotateX = dragAmount * 20 * (pi / 180);
    } else if (isNext) {
      rotateX = dragAmount * 5 * (pi / 180);
    }
    
    return Transform(
      transform: Matrix4.identity()
        // ignore: deprecated_member_use
        ..translate(0.0, translateY)
        ..rotateX(rotateX),
      alignment: Alignment.topCenter,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: widget.margin),
        constraints: BoxConstraints(
          maxHeight: _pagerSize.height,
        ),
        child: widget.children[index],
      ),
    );
  }
}