import 'package:flutter/material.dart';
import '../services/chat_service.dart';
import 'chat.dart';
import '../dekor.dart';

class ChatHub extends StatefulWidget {
  const ChatHub({super.key});

  @override
  State<ChatHub> createState() => _ChatHubState();
}

class _ChatHubState extends State<ChatHub> {
  final ChatService _chatService = ChatService();

  Stream<List> _dohvatiMojeSobe() {
    return _chatService.dohvatiMojeSobe();
  }

  Future<Map<String, dynamic>> _dohvatiPodatkeZaKarticu(
    Map<String, dynamic> soba,
  ) {
    return _chatService.dohvatiPodatkeZaKarticu(soba);
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    return Scaffold(
      backgroundColor: boje.bg,
      body: PozadinaKrugovi(
        krugBoja: boje.C,
        child: SafeArea(
          child: jeWeb
              ? _buildWebView(boje, isDark)
              : _buildMobileView(boje),
        ),
      ),
    );
  }

  Widget _buildWebView(QuickJobsColors boje, bool isDark) {
    final Color boxPozadina = isDark
        ? (boje.A ?? Colors.black).withValues(alpha: 0.08)
        : (boje.A ?? Colors.black).withValues(alpha: 0.10);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
          decoration: BoxDecoration(
            color: (boje.C ?? boje.B)?.withValues(alpha: 1.0),
            border: Border(
              bottom: BorderSide(
                color: (boje.A ?? Colors.black).withValues(alpha: 0.12),
              ),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.arrow_back_rounded, color: boje.A),
                tooltip: 'Natrag',
              ),
              const SizedBox(width: 12),
              Text(
                'Poruke',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: boje.A,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                decoration: BoxDecoration(
                  color: boxPozadina,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: (boje.A ?? Colors.black).withValues(
                      alpha: isDark ? 0.18 : 0.12,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      "Vaši razgovori",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: boje.A?.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(child: _buildListaSoba(boje)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(QuickJobsColors boje) {
    return Column(
      children: [
        _buildHeader(boje),
        Text(
          "Vaši razgovori",
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: boje.A?.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(child: _buildListaSoba(boje)),
      ],
    );
  }

  Widget _buildListaSoba(QuickJobsColors boje) {
    return StreamBuilder<List>(
      stream: _dohvatiMojeSobe(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: boje.A),
          );
        }

        final sobe = snapshot.data ?? [];

        if (sobe.isEmpty) {
          return Center(
            child: Text(
              "Nemate poruka.",
              style: TextStyle(
                color: boje.A,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        }

        return ListView.builder(
          itemCount: sobe.length,
          padding: const EdgeInsets.only(bottom: 20),
          itemBuilder: (context, index) => _buildChatTile(sobe[index], boje),
        );
      },
    );
  }

  Widget _buildChatTile(Map<String, dynamic> soba, QuickJobsColors boje) {
    final bool jeArhiviran = soba['status'] == 'arhivirano';

    return FutureBuilder<Map<String, dynamic>>(
      future: _dohvatiPodatkeZaKarticu(soba),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox(height: 80);

        final d = snapshot.data!;

        return Opacity(
          opacity: jeArhiviran ? 0.6 : 1.0,
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatIndividualni(
                  sobaId: soba['id'],
                  naslovOglasa: d['naslov_oglasa'],
                  imeSugovornika: d['puno_ime'],
                  sugovornikId: d['sugovornik_id'],
                  oglasId: soba['oglas_id'],
                  jeArhiviran: jeArhiviran,
                ),
              ),
            ),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: jeArhiviran ? boje.C?.withValues(alpha: 0.3) : boje.C,
                borderRadius: BorderRadius.circular(15),
                border: jeArhiviran
                    ? Border.all(color: boje.A!.withValues(alpha: 0.2))
                    : null,
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: jeArhiviran
                        ? Colors.grey
                        : boje.bg?.withValues(alpha: 0.6),
                    child: Icon(
                      jeArhiviran ? Icons.archive : Icons.person,
                      color: boje.A,
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          d['puno_ime'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: boje.A,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          jeArhiviran ? "Razgovor završen" : d['zadnja_poruka'],
                          style: TextStyle(
                            color: boje.A?.withValues(alpha: 0.7),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    d['naslov_oglasa'],
                    style: TextStyle(
                      color: boje.A?.withValues(alpha: 0.8),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(QuickJobsColors boje) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 20, 20, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.arrow_back_ios_new, size: 22, color: boje.A),
          ),
          Expanded(
            child: Text(
              "Poruke",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: boje.A,
              ),
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}
