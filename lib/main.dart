import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:file_picker/file_picker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:tabler_icons/tabler_icons.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(statusBarColor: Colors.transparent),
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Use DynamicColorBuilder to support Material You dynamic theming
    return DynamicColorBuilder(
      builder: (ColorScheme? lightColorScheme, ColorScheme? darkColorScheme) {
        return MaterialApp(
          title: 'PDF Viewer',
          debugShowCheckedModeBanner: false,
          // Apply Material 3 theme with dynamic colors or fallback colors
          theme: ThemeData(
            colorScheme:
                lightColorScheme ??
                ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.light,
                ),
            useMaterial3: true,
            fontFamily: GoogleFonts.roboto().fontFamily,
            textTheme: GoogleFonts.robotoTextTheme(),
          ),
          darkTheme: ThemeData(
            colorScheme:
                darkColorScheme ??
                ColorScheme.fromSeed(
                  seedColor: Colors.blue,
                  brightness: Brightness.dark,
                ),
            useMaterial3: true,
            fontFamily: GoogleFonts.roboto().fontFamily,
            textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme),
          ),
          // Use system theme by default
          themeMode: ThemeMode.system,
          home: const SplashScreen(),
        );
      },
    );
  }
}

// New SplashScreen widget for animated transitions
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeIn),
      ),
    );

    _animationController.forward();

    // Navigate to HomePage after animation completes
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          PageRouteBuilder(
            pageBuilder:
                (context, animation, secondaryAnimation) => const HomePage(),
            transitionDuration: const Duration(milliseconds: 800),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              var fadeAnim = Tween<double>(
                begin: 0.0,
                end: 1.0,
              ).animate(animation);
              return FadeTransition(opacity: fadeAnim, child: child);
            },
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: FadeTransition(
                    opacity: _opacityAnimation,
                    child: Icon(
                      TablerIcons.file_text,
                      size: 120,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                FadeTransition(
                  opacity: _opacityAnimation,
                  child: Text(
                    'PDF Viewer',
                    style: GoogleFonts.roboto(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                FadeTransition(
                  opacity: _animationController,
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  String? _pdfPath;
  bool _isLoading = false;
  String? _errorMessage;

  // Animation controller for UI elements
  late AnimationController _animController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animations
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));

    // Start animations
    _animController.forward();

    // Check for shared PDF file intents
    _handleIntentDataIfAny();
  }

  // Check if app was opened with a PDF file intent
  Future<void> _handleIntentDataIfAny() async {
    // This would be implemented with platform channels for intent handling
    // For now, it's a placeholder for the feature
    final intent = await MethodChannel('com.saksham.pdfviewer/intent').invokeMethod('getIntent');
    if (intent != null && intent['type'] == 'application/pdf') {
      setState(() {
        _pdfPath = intent['path'];
      });

      // Navigate to PDF viewer page with animation
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PDFViewerPage(pdfPath: _pdfPath!),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  // Pick a file from storage and convert to PDF if necessary
  Future<void> _pickPDF() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.any,
      );

      if (result != null && result.files.single.path != null) {
        String filePath = result.files.single.path!;
        String fileExtension = filePath.split('.').last.toLowerCase();

        if (fileExtension != 'pdf') {
          // Convert to PDF
          final pdf = pw.Document();
          final file = File(filePath);
          final fileName = file.path.split('/').last;

          pdf.addPage(
            pw.Page(
              build: (pw.Context context) => pw.Center(
                child: pw.Text('Converted from $fileName'),
              ),
            ),
          );

          final output = await getTemporaryDirectory();
          final pdfFile = File("${output.path}/$fileName.pdf");
          await pdfFile.writeAsBytes(await pdf.save());

          filePath = pdfFile.path;
        }

        setState(() {
          _pdfPath = filePath;
          _isLoading = false;
        });

        // Navigate to PDF viewer page with animation
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PDFViewerPage(pdfPath: _pdfPath!),
            ),
          );
        }
      } else {
        // User canceled the picker
        setState(() {
          _isLoading = false;
          _errorMessage = "No file selected";
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = "Error picking file: ${e.toString()}";
      });
    }
  }

  // Create a new PDF file
  Future<void> _createPDF() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) => pw.Center(
          child: pw.Text('Hello World'),
        ),
      ),
    );

    final output = await getTemporaryDirectory();
    final file = File("${output.path}/example.pdf");
    await file.writeAsBytes(await pdf.save());

    setState(() {
      _pdfPath = file.path;
    });

    // Navigate to PDF viewer page with animation
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewerPage(pdfPath: _pdfPath!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  // App icon with bounce animation
                  TweenAnimationBuilder(
                    tween: Tween<double>(begin: 0.8, end: 1.0),
                    duration: const Duration(seconds: 2),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(scale: value, child: child);
                    },
                    child: Icon(
                      TablerIcons.file_text,
                      size: 80,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'PDF Viewer',
                    style: GoogleFonts.roboto(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'View your PDF files with Material You design',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Animated Open PDF button with pill shape
                  FilledButton(
                    onPressed: _isLoading ? null : _pickPDF,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      shape: const StadiumBorder(), // Pill shape
                      elevation: 0,
                      animationDuration: const Duration(milliseconds: 300),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return colorScheme.onPrimaryContainer.withAlpha(
                            51,
                          ); // 20% opacity
                        }
                        return null;
                      }),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLoading
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimaryContainer,
                                strokeWidth: 2.5,
                              ),
                            )
                            : Icon(
                              TablerIcons.file_upload,
                              color: colorScheme.onPrimaryContainer,
                            ),
                        const SizedBox(width: 12),
                        Text(
                          _isLoading ? 'Opening...' : 'Open File',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Animated Create PDF button with pill shape
                  FilledButton(
                    onPressed: _isLoading ? null : _createPDF,
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 32,
                      ),
                      backgroundColor: colorScheme.primaryContainer,
                      foregroundColor: colorScheme.onPrimaryContainer,
                      shape: const StadiumBorder(), // Pill shape
                      elevation: 0,
                      animationDuration: const Duration(milliseconds: 300),
                    ).copyWith(
                      overlayColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.pressed)) {
                          return colorScheme.onPrimaryContainer.withAlpha(
                            51,
                          ); // 20% opacity
                        }
                        return null;
                      }),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLoading
                            ? SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: colorScheme.onPrimaryContainer,
                                strokeWidth: 2.5,
                              ),
                            )
                            : Icon(
                              TablerIcons.file_plus,
                              color: colorScheme.onPrimaryContainer,
                            ),
                        const SizedBox(width: 12),
                        Text(
                          _isLoading ? 'Creating...' : 'Create PDF',
                          style: GoogleFonts.roboto(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Error message if any
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 24),
                    TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 300),
                      tween: Tween<double>(begin: 0, end: 1),
                      builder: (context, value, child) {
                        return Opacity(
                          opacity: value,
                          child: Transform.translate(
                            offset: Offset(0, 20 * (1 - value)),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(TablerIcons.alert_circle, color: colorScheme.error),
                            const SizedBox(width: 12),
                            Flexible(
                              child: Text(
                                _errorMessage!,
                                style: TextStyle(color: colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class PDFViewerPage extends StatefulWidget {
  final String pdfPath;

  const PDFViewerPage({super.key, required this.pdfPath});

  @override
  State<PDFViewerPage> createState() => _PDFViewerPageState();
}

class _PDFViewerPageState extends State<PDFViewerPage>
    with SingleTickerProviderStateMixin {
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = '';
  late PDFViewController _pdfViewController;
  String _extractedText = ''; // For storing extracted text

  // Animation controller for page transitions
  late AnimationController _pageAnimController;
  late Animation<double> _pageScaleAnimation;
  late Animation<double> _pageOpacityAnimation;

  @override
  void initState() {
    super.initState();

    _pageAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _pageScaleAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimController, curve: Curves.easeOutCubic),
    );

    _pageOpacityAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _pageAnimController, curve: Curves.easeOutCubic),
    );

    _pageAnimController.forward();
  }

  @override
  void dispose() {
    _pageAnimController.dispose();
    super.dispose();
  }

  Future<void> _extractText() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Placeholder for text extraction logic
      String text = "Extracted text from PDF";

      setState(() {
        _extractedText = text;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _errorMessage = "Error extracting text: ${e.toString()}";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _getFileName(widget.pdfPath),
          style: const TextStyle(fontSize: 18),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: colorScheme.surfaceContainerHighest,
        foregroundColor: colorScheme.onSurfaceVariant,
        actions: [
          if (_totalPages > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Center(
                child: Text(
                  'Page ${_currentPage + 1} of $_totalPages',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.copy, color: colorScheme.onSurfaceVariant),
            onPressed: _extractText,
          ),
        ],
      ),
      body:
          _hasError
              ? _buildErrorWidget()
              : ScaleTransition(
                scale: _pageScaleAnimation,
                child: FadeTransition(
                  opacity: _pageOpacityAnimation,
                  child: Stack(
                    children: [
                      PDFView(
                        filePath: widget.pdfPath,
                        enableSwipe: true,
                        swipeHorizontal: true,
                        autoSpacing: true,
                        pageFling: true,
                        onRender: (pages) {
                          setState(() {
                            _totalPages = pages!;
                            _isLoading = false;
                          });
                        },
                        onError: (error) {
                          setState(() {
                            _isLoading = false;
                            _hasError = true;
                            _errorMessage = "Error loading PDF: $error";
                          });
                        },
                        onPageError: (page, error) {
                          setState(() {
                            _isLoading = false;
                            _hasError = true;
                            _errorMessage = "Error on page $page: $error";
                          });
                        },
                        onViewCreated: (PDFViewController pdfViewController) {
                          _pdfViewController = pdfViewController;
                        },
                        onPageChanged: (int? page, int? total) {
                          setState(() {
                            _currentPage = page!;
                          });
                        },
                      ),
                      if (_isLoading)
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                width: 60,
                                height: 60,
                                child: CircularProgressIndicator(
                                  color: colorScheme.primary,
                                  strokeWidth: 3,
                                ),
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'Loading PDF...',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      // Navigation buttons
      bottomNavigationBar:
          _hasError || _totalPages <= 1
              ? null
              : BottomAppBar(
                color: colorScheme.surfaceContainerHighest,
                elevation: 0,
                height: 80,
                padding: EdgeInsets.zero,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavigationButton(
                      icon: TablerIcons.chevron_left,
                      label: 'Previous',
                      onPressed:
                          _currentPage > 0
                              ? () {
                                // Add scale animation when changing pages
                                _pageAnimController.reset();
                                _pdfViewController.setPage(_currentPage - 1);
                                _pageAnimController.forward();
                              }
                              : null,
                      colorScheme: colorScheme,
                    ),
                    _buildNavigationButton(
                      icon: TablerIcons.chevron_right,
                      label: 'Next',
                      onPressed:
                          _currentPage < _totalPages - 1
                              ? () {
                                // Add scale animation when changing pages
                                _pageAnimController.reset();
                                _pdfViewController.setPage(_currentPage + 1);
                                _pageAnimController.forward();
                              }
                              : null,
                      colorScheme: colorScheme,
                    ),
                  ],
                ),
              ),
    );
  }

  Widget _buildNavigationButton({
    required IconData icon,
    required String label,
    required VoidCallback? onPressed,
    required ColorScheme colorScheme,
  }) {
    return FilledButton.tonalIcon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        backgroundColor: colorScheme.secondaryContainer,
        foregroundColor: colorScheme.onSecondaryContainer,
        disabledBackgroundColor: colorScheme.secondaryContainer.withAlpha(
          128,
        ), // 50% opacity
        disabledForegroundColor: colorScheme.onSecondaryContainer.withAlpha(
          128,
        ), // 50% opacity
      ),
      icon: Icon(icon, size: 20),
      label: Text(label),
    );
  }

  Widget _buildErrorWidget() {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: TweenAnimationBuilder<double>(
          duration: const Duration(milliseconds: 500),
          tween: Tween<double>(begin: 0, end: 1),
          curve: Curves.easeOutCubic,
          builder: (context, value, child) {
            return Opacity(
              opacity: value,
              child: Transform.scale(scale: 0.8 + (0.2 * value), child: child),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                TablerIcons.alert_circle,
                size: 64,
                color: colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Unable to Load PDF',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  shape: const StadiumBorder(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getFileName(String filePath) {
    final file = File(filePath);
    final fileName = file.path.split('/').last;
    return fileName;
  }
}
