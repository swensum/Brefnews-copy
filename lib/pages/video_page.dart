import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:marvelous_carousel/marvelous_carousel.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../language/app_localizations.dart';
import '../provider/news_provider.dart';
import '../models/video_model.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  int? _lastActiveIndex;
  bool _isFirstLoad = true;
  
  // Video player controllers
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int? _currentVideoIndex;

  // Video progress state
  Duration _currentPosition = Duration.zero;
  Duration _totalDuration = Duration.zero;
  
  // Volume state
  bool _isMuted = false;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      newsProvider.loadVideos();
    });
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  String? _getVideoUrlFromModel(VideoArticle video) {
    if (video.videoUrl.isNotEmpty) {
      return video.videoUrl;
    }
    return null;
  }

  void _videoListener() {
    if (_videoController != null && mounted) {
      setState(() {
        _currentPosition = _videoController!.value.position;
        _totalDuration = _videoController!.value.duration;
      });
    }
  }

  Future<void> _initializeVideoPlayer(int index, VideoArticle video) async {
    _videoController?.removeListener(_videoListener);
    _videoController?.dispose();
    _chewieController?.dispose();

    try {
      String? videoUrl = _getVideoUrlFromModel(video);
      
      if (videoUrl == null || videoUrl.isEmpty) {
        setState(() {
          _currentVideoIndex = index;
        });
        return;
      }
      
     _videoController = VideoPlayerController.networkUrl(
  Uri.parse(videoUrl),
);
      await _videoController!.initialize().then((_) {
        _videoController!.setLooping(false);
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });

      _videoController!.addListener(_videoListener);

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        showControls: false,
        allowFullScreen: false,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: Container(
          color: Colors.black,
          child: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
            ),
          ),
        ),
        materialProgressColors: ChewieProgressColors(
          playedColor: Colors.blue,
          handleColor: Colors.blue,
          backgroundColor: Colors.grey,
          bufferedColor: Colors.grey,
        ),
        errorBuilder: (context, errorMessage) {
          return Container(
            color: Colors.black,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, color: Colors.white, size: 50),
                  SizedBox(height: 10),
                  Text(
                    'Video unavailable',
                    style: TextStyle(color: Colors.white),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'Tap to retry',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
          );
        },
      );

      setState(() {
        _currentVideoIndex = index;
        _currentPosition = Duration.zero;
        _totalDuration = _videoController!.value.duration;
      });

    } catch (e) {
      setState(() {
        _currentVideoIndex = index;
      });
    }
  }

  void _toggleVideoPlayback() {
    if (_videoController != null) {
      if (_videoController!.value.isPlaying) {
        _videoController!.pause();
      } else {
        _videoController!.play();
      }
    } else if (_currentVideoIndex != null) {
      final newsProvider = Provider.of<NewsProvider>(context, listen: false);
      if (_currentVideoIndex! < newsProvider.videos.length) {
        _initializeVideoPlayer(_currentVideoIndex!, newsProvider.videos[_currentVideoIndex!]);
      }
    }
  }

  void _toggleMute() {
    if (_videoController != null) {
      setState(() {
        _isMuted = !_isMuted;
        _videoController!.setVolume(_isMuted ? 0.0 : 1.0);
      });
    }
  }

  void _handleAutoPlay(bool isActive, VideoArticle video, int index) {
    _autoPlayTimer?.cancel();

    if (isActive && _currentVideoIndex != index) {
      _autoPlayTimer = Timer(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        if (_currentPage == index) {
          _initializeVideoPlayer(index, video);
          _lastActiveIndex = index;
          _isFirstLoad = false;
        }
      });
    } else if (!isActive && _currentVideoIndex == index) {
      _autoPlayTimer = Timer(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        if (_videoController != null && _videoController!.value.isPlaying) {
          _videoController!.pause();
        }
      });
    }
  }

  void _onPageChanged(int index) {
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
    
    _autoPlayTimer?.cancel();
    
    setState(() {
      _currentPage = index;
      _lastActiveIndex = null;
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _autoPlayTimer = Timer(const Duration(milliseconds: 400), () {
        if (mounted && _currentPage == index) {
          final newsProvider = Provider.of<NewsProvider>(context, listen: false);
          if (index < newsProvider.videos.length) {
            _initializeVideoPlayer(index, newsProvider.videos[index]);
          }
        }
      });
    });
  }

  void _handleInitialAutoPlay() {
    if (_isFirstLoad && _currentPage == 0 && _currentVideoIndex == null) {
      _isFirstLoad = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _autoPlayTimer = Timer(const Duration(milliseconds: 500), () {
          if (mounted) {
            final newsProvider = Provider.of<NewsProvider>(context, listen: false);
            if (newsProvider.videos.isNotEmpty) {
              _initializeVideoPlayer(0, newsProvider.videos[0]);
            }
          }
        });
      });
    }
  }

  Future<void> _launchVideoUrl(String url) async {
    String rawUrl = url.trim();
    if (!rawUrl.startsWith("http")) {
      rawUrl = "https://$rawUrl";
    }

    final Uri videoUrl = Uri.parse(rawUrl);

    try {
      
      final launched = await launchUrl(videoUrl, mode: LaunchMode.platformDefault);
      
      if (!launched) {
    if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Could not launch $rawUrl"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
     if (!mounted) return;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error opening video: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  

  void _onShareVideo(VideoArticle video) {
  final translatedTitle = video.getTranslatedTitle(context);
  final translatedSourceName = video.getTranslatedSourceName(context);
  final shareText = _buildVideoShareText(video, translatedTitle, translatedSourceName);
  // ignore: deprecated_member_use
  Share.share(shareText, subject: translatedTitle);
}

String _buildVideoShareText(VideoArticle video, String translatedTitle, String translatedSourceName) {
  return """
🎬 $translatedTitle

📺 Source: $translatedSourceName
⏰ ${video.timeAgo}

🔗 Watch here: ${video.videoUrl}

📲 Shared via BrefNews
Download the app for video news updates!
    """
        .trim();
}

  Widget _buildVideoProgressBar() {
    final screenWidth = MediaQuery.of(context).size.width;
    
    final progress = _totalDuration.inSeconds > 0 
        ? _currentPosition.inSeconds / _totalDuration.inSeconds 
        : 0.0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.05),
      child: Column(
        children: [
          GestureDetector(
            onTapDown: (details) {
              final box = context.findRenderObject() as RenderBox?;
              if (box != null && _videoController != null) {
                final localPosition = box.globalToLocal(details.globalPosition);
                final progressWidth = box.size.width;
                final relativePosition = localPosition.dx.clamp(0.0, progressWidth);
                final newProgress = relativePosition / progressWidth;
                final newPosition = Duration(seconds: (newProgress * _totalDuration.inSeconds).toInt());
                _videoController!.seekTo(newPosition);
              }
            },
            child: Container(
              height: 4,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
              child: Stack(
                children: [
                  Container(
                    height: 4,
                    width: progress * (MediaQuery.of(context).size.width - (screenWidth * 0.1)),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Positioned(
                    left: progress * (MediaQuery.of(context).size.width - (screenWidth * 0.1)) - 6,
                    top: -4,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                _formatDuration(_currentPosition),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: screenWidth * 0.03,
                ),
              ),
              Text(
                _formatDuration(_totalDuration),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: screenWidth * 0.03,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildVideoCard(VideoArticle video, bool isActive, int index) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (isActive && _lastActiveIndex != index) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAutoPlay(isActive, video, index);
      });
    }

    return GestureDetector(
      onTap: _toggleVideoPlayback,
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.004),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black12, blurRadius: 8, spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              if (isActive && _currentVideoIndex == index && _chewieController != null)
                SizedBox(
                  width: double.infinity,
                  height: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: FittedBox(
                      fit: BoxFit.cover,
                      child: SizedBox(
                        width: _videoController!.value.size.width,
                        height: _videoController!.value.size.height,
                        child: Chewie(controller: _chewieController!),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[900]!, Colors.purple[900]!],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.play_circle_filled,
                      color: Colors.white.withValues(alpha: 0.5),
                      size: 60,
                    ),
                  ),
                ),

              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: IgnorePointer(
                  child: Container(
                    height: screenHeight * 0.45,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black,
                          Color.fromARGB(220, 0, 0, 0),
                          Color.fromARGB(120, 0, 0, 0),
                          Colors.transparent,
                        ],
                        stops: [0.0, 0.4, 0.75, 1.0],
                      ),
                    ),
                  ),
                ),
              ),

              Positioned(
                left: screenWidth * 0.05,
                right: screenWidth * 0.05,
                bottom: screenHeight * 0.07,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (video.sourceLogoUrl != null)
                          Container(
                            width: screenWidth * 0.06,
                            height: screenWidth * 0.06,
                            margin: EdgeInsets.only(right: screenWidth * 0.02),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: Colors.white,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                video.sourceLogoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey[800],
                                    child: Icon(
                                      Icons.article,
                                      color: Colors.white,
                                      size: screenWidth * 0.03,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                          video.getTranslatedSourceName(context),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.04,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Text(
                       video.getTranslatedTitle(context),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: screenWidth * 0.043,
                        fontWeight: FontWeight.bold,
                        height: 1.25,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: screenHeight * 0.005),
                    Row(
                      children: [
                        Text(
                          video.timeAgo,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: screenWidth * 0.034,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.04),
                        GestureDetector(
                          onTap: () => _launchVideoUrl(video.platformUrl),
                          child: Text(
                             video.getTranslatedPlatformName(context), 
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: screenWidth * 0.034,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                              decorationColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              Positioned(
                top: screenHeight * 0.03,
                right: screenWidth * 0.04,
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () => _onShareVideo(video),
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.share,
                          color: Colors.white,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    GestureDetector(
                      onTap: _toggleMute,
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.02),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isMuted ? Icons.volume_off : Icons.volume_up,
                          color: Colors.white,
                          size: screenWidth * 0.05,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              if (isActive && _currentVideoIndex == index)
                Positioned(
                  bottom: screenHeight * 0,
                  left: 0,
                  right: 0,
                  child: _buildVideoProgressBar(),
                ),

              if (isActive && 
                  _currentVideoIndex == index && 
                  _videoController != null && 
                  !_videoController!.value.isPlaying)
                Positioned.fill(
                  child: Container(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: Center(
                      child: Container(
                        padding: EdgeInsets.all(screenWidth * 0.04),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.7),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: screenWidth * 0.1,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingCarousel() {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      children: List.generate(2, (index) {
        return Positioned.fill(
          child: Transform.translate(
            offset: Offset(0, index * 20.0),
            child: Transform.scale(
              scale: 1.0 - (index * 0.05),
              child: Opacity(
                opacity: 1.0 - (index * 0.3),
                child: Padding(
                  padding: EdgeInsets.all(screenWidth * 0.03),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[900],
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 8,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.grey[800],
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.videocam_outlined,
            color: Colors.grey[600],
            size: screenHeight * 0.15,
          ),
          SizedBox(height: screenHeight * 0.03),
          Text(
            localizations.noVideosAvailable,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            localizations.checkBackLater,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: screenWidth * 0.04,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.03),
          ElevatedButton(
            onPressed: () {
              final newsProvider = Provider.of<NewsProvider>(context, listen: false);
              newsProvider.refreshVideos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
            ),
            child: Text(
              localizations.refresh,
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final localizations = AppLocalizations.of(context)!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: Colors.red[400],
            size: screenHeight * 0.1,
          ),
          SizedBox(height: screenHeight * 0.02),
          Text(
            localizations.failedToLoadVideos,
            style: TextStyle(
              color: Colors.white,
              fontSize: screenWidth * 0.05,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: screenHeight * 0.01),
          Text(
            error,
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: screenWidth * 0.035,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: screenHeight * 0.03),
          ElevatedButton(
            onPressed: () {
              final newsProvider = Provider.of<NewsProvider>(context, listen: false);
              newsProvider.refreshVideos();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.06,
                vertical: screenHeight * 0.02,
              ),
            ),
            child: Text(
              localizations.retry,
              style: TextStyle(fontSize: screenWidth * 0.04),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Consumer<NewsProvider>(
          builder: (context, newsProvider, child) {
            if (!newsProvider.isLoadingVideos && 
                newsProvider.videosError == null && 
                newsProvider.videos.isNotEmpty &&
                _isFirstLoad) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleInitialAutoPlay();
              });
            }
            
            if (newsProvider.isLoadingVideos) {
              return _buildLoadingCarousel();
            }
            
            if (newsProvider.videosError != null) {
              return _buildErrorState(newsProvider.videosError!);
            }
            
            if (newsProvider.videos.isEmpty) {
              return _buildEmptyState();
            }
            
            return MarvelousCarousel(
              pagerType: PagerType.stack,
              margin: 8,
              scrollDirection: Axis.vertical,
              reverse: true,
              dotsVisible: false,
              onPageChanged: _onPageChanged,
              children: newsProvider.videos.asMap().entries.map((entry) {
                int index = entry.key;
                VideoArticle video = entry.value;
                bool isActive = index == _currentPage;

                return AnimatedScale(
                  scale: isActive ? 1.0 : 0.98,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  child: AnimatedOpacity(
                    opacity: isActive ? 1.0 : 1.0,
                    duration: const Duration(milliseconds: 300),
                    child: _buildVideoCard(video, isActive, index),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }
}