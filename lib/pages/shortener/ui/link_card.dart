import 'package:material_ui/material_ui.dart';

import '../../../entities/short_link/short_link.dart';
import '../../../shared/ui/app_style.dart';

class LinkCard extends StatelessWidget {
  const LinkCard({
    required this.link,
    required this.busy,
    required this.onCopy,
    required this.onQr,
    required this.onDelete,
    super.key,
  });
  final ShortLink link;
  final bool busy;
  final VoidCallback onCopy;
  final VoidCallback onQr;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final host = Uri.tryParse(link.originalUrl)?.host ?? link.originalUrl;
    final date = link.expiresAt;
    final status = link.isExpired
        ? 'Срок истёк'
        : date == null
        ? 'Бессрочно'
        : 'До ${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppStyle.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppStyle.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xff2b3325),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.link, color: AppStyle.accent, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  host,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppStyle.muted, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                link.isExpired ? Icons.schedule : Icons.check_circle_outline,
                size: 15,
                color: link.isExpired ? AppStyle.muted : AppStyle.accent,
              ),
            ],
          ),
          const SizedBox(height: 14),
          SelectableText(
            link.shortUrl,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              letterSpacing: -.4,
              color: AppStyle.accent,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            link.originalUrl,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppStyle.muted, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Text(
            status,
            style: const TextStyle(fontSize: 11, color: AppStyle.muted),
          ),
          const Padding(
            padding: EdgeInsets.only(top: 10, bottom: 4),
            child: Divider(height: 1),
          ),
          Wrap(
            spacing: 2,
            children: [
              TextButton.icon(
                onPressed: onCopy,
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Копировать', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: link.isExpired ? null : onQr,
                icon: const Icon(Icons.qr_code_rounded, size: 17),
                label: const Text('QR-код', style: TextStyle(fontSize: 12)),
              ),
              TextButton.icon(
                onPressed: busy ? null : onDelete,
                style: TextButton.styleFrom(foregroundColor: AppStyle.muted),
                icon: const Icon(Icons.delete_outline_rounded, size: 17),
                label: const Text('Удалить', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
