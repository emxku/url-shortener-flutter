import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../entities/short_link/short_link.dart';
import '../../../features/manage_links/manage_links.dart';
import '../../../shared/api/api_client.dart';
import '../../../shared/ui/app_style.dart';
import 'link_card.dart';

class ShortenerPage extends ConsumerStatefulWidget {
  const ShortenerPage({super.key});
  @override
  ConsumerState<ShortenerPage> createState() => _ShortenerPageState();
}

class _ShortenerPageState extends ConsumerState<ShortenerPage> {
  final _url = TextEditingController();
  final _form = GlobalKey<FormState>();
  final _collectionKey = GlobalKey();
  @override
  void dispose() {
    _url.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    await ref.read(linkControllerProvider.notifier).create(_url.text);
    if (!mounted || ref.read(linkControllerProvider).error != null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final target = _collectionKey.currentContext;
      if (target != null) {
        Scrollable.ensureVisible(
          target,
          duration: Duration(
            milliseconds: MediaQuery.disableAnimationsOf(context) ? 0 : 400,
          ),
          curve: Curves.easeOutCubic,
        );
      }
    });
  }

  Future<void> _delete(ShortLink link) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить ссылку?'),
        content: const Text(
          'Короткая ссылка перестанет работать для всех, у кого она есть.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await ref.read(linkControllerProvider.notifier).delete(link);
    }
  }

  Future<void> _copy(String value) async {
    try {
      await Clipboard.setData(ClipboardData(text: value));
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Ссылка скопирована')));
      }
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Не удалось скопировать. Выделите ссылку вручную.'),
          ),
        );
      }
    }
  }

  void _qr(ShortLink link) {
    final repository = ref.read(linkRepositoryProvider);
    showDialog<void>(
      context: context,
      builder: (_) => _QrDialog(load: () => repository.qr(link.code)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(linkControllerProvider);
    final reduced = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: CustomScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                  sliver: SliverToBoxAdapter(
                    child: Reveal(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: AppStyle.accent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.link_rounded,
                                  color: AppStyle.background,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Flexible(
                                child: Text(
                                  'shortly',
                                  style: TextStyle(
                                    fontSize: 25,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1,
                                  ),
                                ),
                              ),
                              const Spacer(),
                              if (MediaQuery.sizeOf(context).width >= 380 &&
                                  MediaQuery.textScalerOf(context).scale(10) <=
                                      12)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: AppStyle.border),
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  child: const Text(
                                    'МЕНЬШЕ — ЛУЧШЕ',
                                    style: TextStyle(
                                      fontSize: 9,
                                      letterSpacing: 1.2,
                                      fontWeight: FontWeight.w700,
                                      color: AppStyle.muted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 38),
                          const Text(
                            'Длинные ссылки. ',
                            style: TextStyle(
                              fontSize: 36,
                              height: 1.12,
                              letterSpacing: -1.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Теперь короче.',
                            style: TextStyle(
                              fontSize: 36,
                              height: 1.16,
                              color: AppStyle.accent,
                              letterSpacing: -1.7,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Один адрес. Меньше символов.\nБольше места для важного.',
                            style: TextStyle(
                              color: AppStyle.muted,
                              height: 1.6,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xff262d20), AppStyle.surface],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                color: const Color(0xff3c4731),
                              ),
                            ),
                            child: Form(
                              key: _form,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.add_link_rounded,
                                        size: 20,
                                        color: AppStyle.accent,
                                      ),
                                      SizedBox(width: 8),
                                      Flexible(
                                        child: Text(
                                          'Новая ссылка',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 18),
                                  TextFormField(
                                    controller: _url,
                                    validator: validateUrl,
                                    keyboardType: TextInputType.url,
                                    autocorrect: false,
                                    enableSuggestions: false,
                                    textInputAction: TextInputAction.go,
                                    style: const TextStyle(fontSize: 15),
                                    onFieldSubmitted: (_) {
                                      if (!state.busy && !state.loading) {
                                        _submit();
                                      }
                                    },
                                    decoration: const InputDecoration(
                                      hintText:
                                          'https://example.com/your-long-link',
                                      labelText: 'Исходная ссылка',
                                      errorMaxLines: 3,
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  FilledButton(
                                    onPressed: state.busy || state.loading
                                        ? null
                                        : _submit,
                                    child: AnimatedSwitcher(
                                      duration: Duration(
                                        milliseconds: reduced ? 0 : 180,
                                      ),
                                      child: state.busy
                                          ? const SizedBox(
                                              key: ValueKey('busy'),
                                              width: 22,
                                              height: 22,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Row(
                                              key: ValueKey('ready'),
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Flexible(
                                                  child: Text(
                                                    'Сократить ссылку',
                                                  ),
                                                ),
                                                SizedBox(width: 12),
                                                Icon(
                                                  Icons.arrow_forward_rounded,
                                                  size: 20,
                                                ),
                                              ],
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  const Text(
                                    'Вставьте ссылку. Остальное — за нами.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppStyle.muted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          AnimatedSize(
                            duration: Duration(milliseconds: reduced ? 0 : 220),
                            curve: Curves.easeOutCubic,
                            child: state.error == null
                                ? const SizedBox(width: double.infinity)
                                : Padding(
                                    padding: const EdgeInsets.only(top: 14),
                                    child: Semantics(
                                      liveRegion: true,
                                      child: Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: const Color(0xff352321),
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        child: Text(
                                          state.error!,
                                          style: TextStyle(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                            height: 1.4,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 32),
                          Row(
                            key: _collectionKey,
                            children: [
                              const Flexible(
                                child: Text(
                                  'Коллекция ссылок',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppStyle.surface,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${state.links.length}',
                                  style: const TextStyle(
                                    color: AppStyle.accent,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Всегда под рукой. Только на этом устройстве.',
                            style: TextStyle(
                              color: AppStyle.muted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.loading)
                  const SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  )
                else if (state.links.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverToBoxAdapter(child: _EmptyCollection()),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    sliver: SliverList.builder(
                      itemCount: state.links.length,
                      findChildIndexCallback: (key) {
                        final index = state.links.indexWhere(
                          (link) => ValueKey(link.shortUrl) == key,
                        );
                        return index < 0 ? null : index;
                      },
                      itemBuilder: (_, index) {
                        final link = state.links[index];
                        return Reveal(
                          key: ValueKey(link.shortUrl),
                          child: LinkCard(
                            link: link,
                            busy: state.busy,
                            onCopy: () => _copy(link.shortUrl),
                            onQr: () => _qr(link),
                            onDelete: () => _delete(link),
                          ),
                        );
                      },
                    ),
                  ),
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 28, 24, 28),
                    child: Text(
                      'МАЛЕНЬКАЯ ССЫЛКА. БОЛЬШИЕ ВОЗМОЖНОСТИ.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 1.4,
                        color: Color(0xff70796c),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyCollection extends StatelessWidget {
  const _EmptyCollection();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppStyle.border),
    ),
    child: Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: const BoxDecoration(
            color: AppStyle.surface,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.bookmarks_outlined,
            color: AppStyle.muted,
            size: 25,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Начнём с первой ссылки?',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        const SizedBox(height: 8),
        const Text(
          'Сократите адрес выше —\nи он появится в вашей коллекции.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppStyle.muted, height: 1.5, fontSize: 13),
        ),
      ],
    ),
  );
}

class _QrDialog extends StatefulWidget {
  const _QrDialog({required this.load});
  final Future<Uint8List> Function() load;
  @override
  State<_QrDialog> createState() => _QrDialogState();
}

class _QrDialogState extends State<_QrDialog> {
  late Future<Uint8List> _image = widget.load();
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('QR-код ссылки'),
    content: SizedBox(
      width: 256,
      height: 256,
      child: FutureBuilder<Uint8List>(
        future: _image,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  snapshot.error is ApiException
                      ? (snapshot.error as ApiException).message
                      : 'Не удалось загрузить QR-код.',
                ),
                TextButton(
                  onPressed: () => setState(() => _image = widget.load()),
                  child: const Text('Повторить'),
                ),
              ],
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.memory(
              snapshot.data!,
              semanticLabel: 'QR-код сокращённой ссылки',
              errorBuilder: (_, _, _) => const Text(
                'Сервер вернул некорректное изображение.',
                style: TextStyle(color: Colors.black),
              ),
            ),
          );
        },
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: const Text('Закрыть'),
      ),
    ],
  );
}
