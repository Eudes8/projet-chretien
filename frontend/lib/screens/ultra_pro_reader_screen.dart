import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/publication.dart';
import '../theme/app_theme.dart';

enum ReadingTheme { light, sepia, dark }
enum FontStyle { serif, sansSerif, mono }

class UltraProReaderScreen extends StatefulWidget {
  final Publication publication;

  const UltraProReaderScreen({super.key, required this.publication});

  @override
  State<UltraProReaderScreen> createState() => _UltraProReaderScreenState();
}

class _UltraProReaderScreenState extends State<UltraProReaderScreen>
    with TickerProviderStateMixin {
  // Controllers
  late QuillController _quillController;
  final ScrollController _scrollController = ScrollController();
  final FlutterTts _tts = FlutterTts();

  // UI State
  bool _isFullscreen = false;
  bool _showControls = true;
  bool _showSettings = false;
  Timer? _hideControlsTimer;

  // Reading Settings
  ReadingTheme _theme = ReadingTheme.sepia;
  FontStyle _fontStyle = FontStyle.serif;
  double _fontSize = 18.0;
  double _lineHeight = 1.6;
  double _letterSpacing = 0.5;
  double _brightness = 1.0;

  // TTS State
  bool _isPlaying = false;
  double _speechRate = 1.0;
  double _pitch = 1.0;

  // Progress
  double _readingProgress = 0.0;
  int _currentPage = 1;
  int _totalPages = 1;
  Duration _readingTime = Duration.zero;
  Timer? _readingTimer;

  // Animations
  late AnimationController _controlsAnimationController;
  late Animation<double> _controlsAnimation;

  @override
  void initState() {
    super.initState();
    _initQuillController();
    _initTts();
    _initAnimations();
    _loadReadingProgress();
    _startReadingTimer();
    _scrollController.addListener(_onScroll);
  }

  void _initQuillController() {
    try {
      if (widget.publication.contenuPrincipal != null &&
          widget.publication.contenuPrincipal!.isNotEmpty) {
        var json = jsonDecode(widget.publication.contenuPrincipal!);
        _quillController = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
      } else {
        _quillController = QuillController.basic();
      }
      _quillController.readOnly = true;
    } catch (e) {
      _quillController = QuillController(
        document: Document()
          ..insert(0, widget.publication.contenuPrincipal ?? ''),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _quillController.readOnly = true;
    }
  }

  void _initTts() {
    _tts.setStartHandler(() => setState(() => _isPlaying = true));
    _tts.setCompletionHandler(() => setState(() => _isPlaying = false));
    _tts.setCancelHandler(() => setState(() => _isPlaying = false));
    _tts.setErrorHandler((msg) => setState(() => _isPlaying = false));
  }

  void _initAnimations() {
    _controlsAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _controlsAnimation = CurvedAnimation(
      parent: _controlsAnimationController,
      curve: Curves.easeInOut,
    );
    _controlsAnimationController.forward();
  }

  Future<void> _loadReadingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reading_progress_${widget.publication.id}';
    setState(() {
      _readingProgress = prefs.getDouble(key) ?? 0.0;
    });
    if (_readingProgress > 0) {
      _scrollToProgress(_readingProgress);
    }
  }

  Future<void> _saveReadingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'reading_progress_${widget.publication.id}';
    await prefs.setDouble(key, _readingProgress);
  }

  void _scrollToProgress(double progress) {
    if (_scrollController.hasClients) {
      final position = _scrollController.position.maxScrollExtent * progress;
      _scrollController.jumpTo(position);
    }
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final max = _scrollController.position.maxScrollExtent;
      final current = _scrollController.position.pixels;
      setState(() {
        _readingProgress = max > 0 ? current / max : 0.0;
      });
      _saveReadingProgress();
    }
  }

  void _startReadingTimer() {
    _readingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _readingTime += const Duration(seconds: 1);
      });
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
      if (_showControls) {
        _controlsAnimationController.forward();
        _resetHideTimer();
      } else {
        _controlsAnimationController.reverse();
      }
    });
  }

  void _resetHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (_showControls && !_showSettings) {
        _toggleControls();
      }
    });
  }

  void _toggleFullscreen() {
    setState(() {
      _isFullscreen = !_isFullscreen;
      if (_isFullscreen) {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
      } else {
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      }
    });
  }

  Future<void> _toggleTts() async {
    if (_isPlaying) {
      await _tts.stop();
    } else {
      final text = _quillController.document.toPlainText();
      await _tts.setSpeechRate(_speechRate);
      await _tts.setPitch(_pitch);
      await _tts.speak(text);
    }
  }

  Color get _backgroundColor {
    switch (_theme) {
      case ReadingTheme.light:
        return Colors.white;
      case ReadingTheme.sepia:
        return const Color(0xFFF4ECD8);
      case ReadingTheme.dark:
        return const Color(0xFF1A1A1A);
    }
  }

  Color get _textColor {
    switch (_theme) {
      case ReadingTheme.light:
        return Colors.black87;
      case ReadingTheme.sepia:
        return const Color(0xFF5F4B32);
      case ReadingTheme.dark:
        return const Color(0xFFE0E0E0);
    }
  }

  TextStyle get _textStyle {
    String fontFamily;
    switch (_fontStyle) {
      case FontStyle.serif:
        fontFamily = 'Libre Baskerville';
        break;
      case FontStyle.sansSerif:
        fontFamily = 'Inter';
        break;
      case FontStyle.mono:
        fontFamily = 'Courier';
        break;
    }

    return GoogleFonts.getFont(
      fontFamily,
      fontSize: _fontSize,
      height: _lineHeight,
      letterSpacing: _letterSpacing,
      color: _textColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: Stack(
        children: [
          // Main Content
          GestureDetector(
            onTap: _toggleControls,
            child: SafeArea(
              child: Column(
                children: [
                  // Progress Bar
                  if (_showControls)
                    FadeTransition(
                      opacity: _controlsAnimation,
                      child: _buildProgressBar(),
                    ),
                  
                  // Reading Content
                  Expanded(
                    child: Opacity(
                      opacity: _brightness,
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        padding: EdgeInsets.symmetric(
                          horizontal: _isFullscreen ? 24 : 16,
                          vertical: 24,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Title
                            Text(
                              widget.publication.titre,
                              style: GoogleFonts.playfairDisplay(
                                fontSize: _fontSize + 8,
                                fontWeight: FontWeight.bold,
                                color: _textColor,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Metadata
                            Row(
                              children: [
                                Icon(
                                  Icons.access_time,
                                  size: 14,
                                  color: _textColor.withOpacity(0.6),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${_estimateReadingTime()} min de lecture',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: _textColor.withOpacity(0.6),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.primaryOrange.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    widget.publication.type,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Content
                            DefaultTextStyle(
                              style: _textStyle,
                              child: QuillEditor.basic(
                                configurations: QuillEditorConfigurations(
                                  controller: _quillController,
                                  readOnly: true,
                                  showCursor: false,
                                  padding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Top Controls
          if (_showControls && !_isFullscreen)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _controlsAnimation,
                child: _buildTopBar(),
              ),
            ),

          // Bottom Controls
          if (_showControls)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _controlsAnimation,
                child: _buildBottomControls(),
              ),
            ),

          // Settings Panel
          if (_showSettings)
            Positioned.fill(
              child: GestureDetector(
                onTap: () => setState(() => _showSettings = false),
                child: Container(
                  color: Colors.black54,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping panel
                      child: _buildSettingsPanel(),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Container(
      height: 3,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryBlue,
            AppTheme.primaryOrange,
          ],
          stops: [_readingProgress, _readingProgress],
        ),
        color: _textColor.withOpacity(0.1),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            _backgroundColor,
            _backgroundColor.withOpacity(0),
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: _textColor),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                widget.publication.titre,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(
                _isFullscreen ? Icons.fullscreen_exit : Icons.fullscreen,
                color: _textColor,
              ),
              onPressed: _toggleFullscreen,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [
            _backgroundColor,
            _backgroundColor.withOpacity(0),
          ],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildControlButton(
              icon: _isPlaying ? Icons.stop : Icons.play_arrow,
              label: 'Audio',
              onPressed: _toggleTts,
            ),
            _buildControlButton(
              icon: Icons.bookmark_border,
              label: 'Marque-page',
              onPressed: () {
                // TODO: Implement bookmarks
              },
            ),
            _buildControlButton(
              icon: Icons.text_fields,
              label: 'Paramètres',
              onPressed: () {
                setState(() => _showSettings = true);
                _hideControlsTimer?.cancel();
              },
            ),
            _buildControlButton(
              icon: Icons.share,
              label: 'Partager',
              onPressed: () {
                // TODO: Implement share
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: _textColor, size: 24),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: _textColor.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsPanel() {
    return Container(
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _textColor.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Title
            Text(
              'Paramètres de lecture',
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 24),

            // Theme Selection
            _buildSettingSection(
              'Thème',
              Row(
                children: [
                  _buildThemeButton(ReadingTheme.light, 'Clair', Colors.white),
                  const SizedBox(width: 12),
                  _buildThemeButton(
                      ReadingTheme.sepia, 'Sépia', const Color(0xFFF4ECD8)),
                  const SizedBox(width: 12),
                  _buildThemeButton(
                      ReadingTheme.dark, 'Sombre', const Color(0xFF1A1A1A)),
                ],
              ),
            ),

            // Font Style
            _buildSettingSection(
              'Police',
              Row(
                children: [
                  _buildFontButton(FontStyle.serif, 'Serif'),
                  const SizedBox(width: 12),
                  _buildFontButton(FontStyle.sansSerif, 'Sans-Serif'),
                  const SizedBox(width: 12),
                  _buildFontButton(FontStyle.mono, 'Mono'),
                ],
              ),
            ),

            // Font Size
            _buildSettingSection(
              'Taille de police: ${_fontSize.toInt()}',
              Slider(
                value: _fontSize,
                min: 12,
                max: 32,
                divisions: 20,
                activeColor: AppTheme.primaryOrange,
                onChanged: (value) => setState(() => _fontSize = value),
              ),
            ),

            // Line Height
            _buildSettingSection(
              'Hauteur de ligne: ${_lineHeight.toStringAsFixed(1)}',
              Slider(
                value: _lineHeight,
                min: 1.0,
                max: 2.5,
                divisions: 15,
                activeColor: AppTheme.primaryBlue,
                onChanged: (value) => setState(() => _lineHeight = value),
              ),
            ),

            // Letter Spacing
            _buildSettingSection(
              'Espacement: ${_letterSpacing.toStringAsFixed(1)}',
              Slider(
                value: _letterSpacing,
                min: 0,
                max: 3,
                divisions: 30,
                activeColor: AppTheme.primaryOrange,
                onChanged: (value) => setState(() => _letterSpacing = value),
              ),
            ),

            // Brightness
            _buildSettingSection(
              'Luminosité: ${(_brightness * 100).toInt()}%',
              Slider(
                value: _brightness,
                min: 0.3,
                max: 1.0,
                divisions: 14,
                activeColor: AppTheme.primaryBlue,
                onChanged: (value) => setState(() => _brightness = value),
              ),
            ),

            // TTS Settings
            const Divider(height: 32),
            Text(
              'Lecture audio',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 16),

            _buildSettingSection(
              'Vitesse: ${_speechRate.toStringAsFixed(1)}x',
              Slider(
                value: _speechRate,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                activeColor: AppTheme.primaryOrange,
                onChanged: (value) => setState(() => _speechRate = value),
              ),
            ),

            _buildSettingSection(
              'Tonalité: ${_pitch.toStringAsFixed(1)}',
              Slider(
                value: _pitch,
                min: 0.5,
                max: 2.0,
                divisions: 15,
                activeColor: AppTheme.primaryBlue,
                onChanged: (value) => setState(() => _pitch = value),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingSection(String title, Widget child) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _textColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildThemeButton(ReadingTheme theme, String label, Color color) {
    final isSelected = _theme == theme;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _theme = theme),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryOrange : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: theme == ReadingTheme.dark ? Colors.white : Colors.black,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFontButton(FontStyle style, String label) {
    final isSelected = _fontStyle == style;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _fontStyle = style),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryBlue.withOpacity(0.1)
                : _textColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryBlue : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: _textColor,
              ),
            ),
          ),
        ),
      ),
    );
  }

  int _estimateReadingTime() {
    final text = _quillController.document.toPlainText();
    final wordCount = text.split(RegExp(r'\s+')).length;
    return (wordCount / 200).ceil(); // 200 words per minute
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _quillController.dispose();
    _tts.stop();
    _readingTimer?.cancel();
    _hideControlsTimer?.cancel();
    _controlsAnimationController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }
}
