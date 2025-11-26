import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/publication.dart';
import '../widgets/premium_gate.dart';

enum ThemeModeOption {
  clair,
  sepia,
  sombre,
}

class ReadingScreen extends StatefulWidget {
  final Publication publication;

  const ReadingScreen({super.key, required this.publication});

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen> {
  final FlutterTts flutterTts = FlutterTts();
  late QuillController _quillController;
  bool isPlaying = false;
  double speechRate = 1.0;
  double fontSize = 18.0;
  String fontFamily = 'Libre Baskerville';
  ThemeModeOption themeMode = ThemeModeOption.sepia;
  bool _showSettings = false;

  @override
  void initState() {
    super.initState();
    _initQuillController();
    _initTts();
  }

  void _initQuillController() {
    try {
      if (widget.publication.contenuPrincipal != null && widget.publication.contenuPrincipal!.isNotEmpty) {
        // Try to parse as Quill JSON Delta
        var json = jsonDecode(widget.publication.contenuPrincipal!);
        _quillController = QuillController(
          document: Document.fromJson(json),
          selection: const TextSelection.collapsed(offset: 0),
        );
        _quillController.readOnly = true;
      } else {
        _quillController = QuillController.basic();
        _quillController.readOnly = true;
      }
    } catch (e) {
      // Fallback to plain text if not JSON
      _quillController = QuillController(
        document: Document()..insert(0, widget.publication.contenuPrincipal ?? ''),
        selection: const TextSelection.collapsed(offset: 0),
      );
      _quillController.readOnly = true;
    }
  }

  void _initTts() {
    flutterTts.setStartHandler(() {
      setState(() {
        isPlaying = true;
      });
    });

    flutterTts.setCompletionHandler(() {
      setState(() {
        isPlaying = false;
      });
    });

    flutterTts.setCancelHandler(() {
      setState(() {
        isPlaying = false;
      });
    });

    flutterTts.setErrorHandler((msg) {
      setState(() {
        isPlaying = false;
      });
    });
  }

  Future<void> _speak(String text) async {
    await flutterTts.setSpeechRate(speechRate);
    await flutterTts.speak(text);
  }

  Future<void> _stop() async {
    await flutterTts.stop();
    setState(() {
      isPlaying = false;
    });
  }

  Color _getBackgroundColor() {
    switch (themeMode) {
      case ThemeModeOption.clair:
        return const Color(0xFFFFFDF7); // Warm white
      case ThemeModeOption.sepia:
        return const Color(0xFFF4ECD8); // Parchment
      case ThemeModeOption.sombre:
        return const Color(0xFF1A1A1A); // Dark gray
    }
  }

  Color _getTextColor() {
    switch (themeMode) {
      case ThemeModeOption.clair:
        return const Color(0xFF2C2C2C);
      case ThemeModeOption.sepia:
        return const Color(0xFF3D3D3D);
      case ThemeModeOption.sombre:
        return const Color(0xFFE8E8E8);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PremiumGate(
      isPaidContent: widget.publication.estPayant,
      child: Scaffold(
      backgroundColor: _getBackgroundColor(),
      body: Stack(
        children: [
          // Main content
          SafeArea(
            child: Column(
              children: [
                // Custom AppBar with book aesthetic
                _buildCustomAppBar(),
                
                // Reading area
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 800),
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Decorative ornament
                            Center(
                              child: Container(
                                width: 60,
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      _getTextColor().withOpacity(0.2),
                                      _getTextColor().withOpacity(0.6),
                                      _getTextColor().withOpacity(0.2),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 40),
                            
                            // Title with elegant styling
                            Text(
                              widget.publication.titre,
                              style: _getTitleStyle(),
                              textAlign: TextAlign.center,
                            ),
                            
                            const SizedBox(height: 15),
                            
                            // Type badge
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getTextColor().withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: _getTextColor().withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  widget.publication.type,
                                  style: GoogleFonts.ebGaramond(
                                    fontSize: 12,
                                    letterSpacing: 2,
                                    fontWeight: FontWeight.w500,
                                    color: _getTextColor().withOpacity(0.7),
                                  ),
                                ),
                              ),
                            ),
                            
                            const SizedBox(height: 50),
                            
                            // Drop cap effect with first letter
                            _buildRichContent(),
                            
                            const SizedBox(height: 80),
                            
                            // Decorative end ornament
                            Center(
                              child: Icon(
                                Icons.auto_stories,
                                size: 24,
                                color: _getTextColor().withOpacity(0.3),
                              ),
                            ),
                            const SizedBox(height: 40),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                
                // Audio controls
                if (isPlaying) _buildAudioControls(),
              ],
            ),
          ),
          
          // Settings panel overlay
          if (_showSettings) _buildSettingsOverlay(),
        ],
      ),
    ),
    );
  }

  Widget _buildCustomAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: Border(
          bottom: BorderSide(
            color: _getTextColor().withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: _getTextColor()),
            onPressed: () => Navigator.pop(context),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(
              isPlaying ? Icons.pause_circle : Icons.play_circle,
              color: _getTextColor(),
            ),
            onPressed: () {
              if (isPlaying) {
                _stop();
              } else {
                _speak(_quillController.document.toPlainText());
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.text_fields, color: _getTextColor()),
            onPressed: () {
              setState(() {
                _showSettings = !_showSettings;
              });
            },
          ),
          IconButton(
            icon: Icon(Icons.palette_outlined, color: _getTextColor()),
            onPressed: () {
              setState(() {
                // Cycle through themes
                themeMode = ThemeModeOption.values[
                    (themeMode.index + 1) % ThemeModeOption.values.length
                ];
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRichContent() {
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: TextTheme(
          bodyMedium: _getTextStyle(),
        ),
      ),
      child: QuillEditor.basic(
        controller: _quillController,
      ),
    );
  }

  TextStyle _getTitleStyle() {
    return GoogleFonts.ebGaramond(
      fontSize: 36,
      fontWeight: FontWeight.bold,
      color: _getTextColor(),
      height: 1.3,
      letterSpacing: 0.5,
    );
  }

  TextStyle _getTextStyle() {
    TextStyle baseStyle;
    switch (fontFamily) {
      case 'Libre Baskerville':
        baseStyle = GoogleFonts.libreBaskerville();
        break;
      case 'EB Garamond':
        baseStyle = GoogleFonts.ebGaramond();
        break;
      case 'Crimson Text':
        baseStyle = GoogleFonts.crimsonText();
        break;
      case 'Lora':
        baseStyle = GoogleFonts.lora();
        break;
      default:
        baseStyle = GoogleFonts.libreBaskerville();
        break;
    }
    return baseStyle.copyWith(
      fontSize: fontSize,
      color: _getTextColor(),
      height: 1.8,
      letterSpacing: 0.3,
    );
  }

  Widget _buildAudioControls() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        border: Border(
          top: BorderSide(
            color: _getTextColor().withOpacity(0.1),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: Icon(Icons.stop, color: _getTextColor()),
            onPressed: _stop,
          ),
          const SizedBox(width: 8),
          Text(
            'Lecture audio en cours...',
            style: GoogleFonts.lato(
              color: _getTextColor().withOpacity(0.7),
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),
          DropdownButton<double>(
            value: speechRate,
            dropdownColor: _getBackgroundColor(),
            icon: Icon(Icons.speed, color: _getTextColor()),
            underline: Container(),
            items: [
              DropdownMenuItem(value: 0.75, child: Text('0.75x', style: TextStyle(color: _getTextColor()))),
              DropdownMenuItem(value: 1.0, child: Text('1.0x', style: TextStyle(color: _getTextColor()))),
              DropdownMenuItem(value: 1.5, child: Text('1.5x', style: TextStyle(color: _getTextColor()))),
            ],
            onChanged: (double? newValue) {
              if (newValue != null) {
                setState(() {
                  speechRate = newValue;
                  if (isPlaying) {
                    _stop().then((_) => _speak(_quillController.document.toPlainText()));
                  }
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsOverlay() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _showSettings = false;
        });
      },
      child: Container(
        color: Colors.black.withOpacity(0.5),
        child: Center(
          child: GestureDetector(
            onTap: () {}, // Prevent closing when tapping panel
            child: Container(
              width: 350,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Paramètres de lecture',
                        style: GoogleFonts.ebGaramond(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: _getTextColor(),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.close, color: _getTextColor()),
                        onPressed: () {
                          setState(() {
                            _showSettings = false;
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Font size slider
                  Row(
                    children: [
                      Icon(Icons.text_fields, color: _getTextColor().withOpacity(0.7), size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 14,
                          max: 28,
                          divisions: 7,
                          activeColor: _getTextColor(),
                          inactiveColor: _getTextColor().withOpacity(0.2),
                          label: '${fontSize.round()}pt',
                          onChanged: (value) {
                            setState(() {
                              fontSize = value;
                            });
                          },
                        ),
                      ),
                      Text(
                        '${fontSize.round()}',
                        style: TextStyle(color: _getTextColor()),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Font family
                  _buildSettingRow(
                    'Police',
                    DropdownButton<String>(
                      value: fontFamily,
                      dropdownColor: _getBackgroundColor(),
                      underline: Container(),
                      style: TextStyle(color: _getTextColor()),
                      items: const [
                        DropdownMenuItem(value: 'Libre Baskerville', child: Text('Baskerville')),
                        DropdownMenuItem(value: 'EB Garamond', child: Text('Garamond')),
                        DropdownMenuItem(value: 'Crimson Text', child: Text('Crimson')),
                        DropdownMenuItem(value: 'Lora', child: Text('Lora')),
                      ],
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            fontFamily = newValue;
                          });
                        }
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Theme mode
                  _buildSettingRow(
                    'Thème',
                    DropdownButton<ThemeModeOption>(
                      value: themeMode,
                      dropdownColor: _getBackgroundColor(),
                      underline: Container(),
                      style: TextStyle(color: _getTextColor()),
                      items: const [
                        DropdownMenuItem(value: ThemeModeOption.clair, child: Text('Clair')),
                        DropdownMenuItem(value: ThemeModeOption.sepia, child: Text('Sépia')),
                        DropdownMenuItem(value: ThemeModeOption.sombre, child: Text('Sombre')),
                      ],
                      onChanged: (ThemeModeOption? newValue) {
                        if (newValue != null) {
                          setState(() {
                            themeMode = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSettingRow(String label, Widget control) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.lato(
            color: _getTextColor().withOpacity(0.7),
            fontSize: 14,
          ),
        ),
        control,
      ],
    );
  }

  
  @override
  void dispose() {
    flutterTts.stop();
    _quillController.dispose();
    super.dispose();
  }
}
