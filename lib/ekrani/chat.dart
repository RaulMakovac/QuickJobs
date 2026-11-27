import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/chat_service.dart';
import '../dekor.dart';
import 'korisnicki_profil.dart';
import 'oglas.dart';

class ChatIndividualni extends StatefulWidget {
  final String sobaId;
  final String naslovOglasa;
  final String imeSugovornika;
  final String sugovornikId;
  final String oglasId;
  final bool jeArhiviran;

  const ChatIndividualni({
    super.key,
    required this.sobaId,
    required this.naslovOglasa,
    required this.imeSugovornika,
    required this.sugovornikId,
    required this.oglasId,
    required this.jeArhiviran,
  });

  @override
  State<ChatIndividualni> createState() => _ChatIndividualniState();
}

class _ChatIndividualniState extends State<ChatIndividualni> {
  final _porukaController = TextEditingController();
  final ChatService _chatService = ChatService();
  late final String mojId;

  @override
  void initState() {
    super.initState();
    mojId = _chatService.trenutniKorisnikId!;
  }

  @override
  void dispose() {
    _porukaController.dispose();
    super.dispose();
  }

  Future<void> _navigirajNaOglas() async {
    try {
      final oglasObjekt = await _chatService.dohvatiOglasZaChat(widget.oglasId);

      if (oglasObjekt != null && mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                DetaljiOglasa(oglas: oglasObjekt, samoPregled: true),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Greška pri otvaranju oglasa.")),
        );
      }
    }
  }

  Future<void> _posaljiPoruku(bool chatZakljucan) async {
    if (chatZakljucan) return;

    final tekst = _porukaController.text.trim();

    if (tekst.isEmpty) return;

    _porukaController.clear();

    try {
      await _chatService.posaljiPoruku(sobaId: widget.sobaId, tekst: tekst);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Greška: $e")));
      }
    }
  }

  Future<void> _obrisiChatOdmah(QuickJobsColors boje) async {
    final potvrda = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: boje.bg,
        title: Text("Obriši razgovor?", style: TextStyle(color: boje.A)),
        content: Text(
          "Želite li odmah trajno obrisati ovaj razgovor?",
          style: TextStyle(color: boje.A),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text("Ne", style: TextStyle(color: boje.A)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Obriši", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (potvrda == true) {
      try {
        await _chatService.obrisiChatSobu(widget.sobaId);

        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Greška pri brisanju: $e")));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final boje = Theme.of(context).extension<QuickJobsColors>()!;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final bool jeWeb = MediaQuery.sizeOf(context).width >= 800;

    return StreamBuilder<List>(
      stream: _chatService.pratiSobu(widget.sobaId),
      builder: (context, snapshot) {
        bool arhiviranIzBaze = widget.jeArhiviran;

        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          arhiviranIzBaze = snapshot.data!.first['status'] == 'arhivirano';
        }

        return Scaffold(
          backgroundColor: boje.bg,
          appBar: jeWeb
              ? null
              : AppBar(
                  toolbarHeight: 90,
                  backgroundColor: arhiviranIzBaze ? boje.B : boje.C,
                  automaticallyImplyLeading: false,
                  elevation: 0,
                  actions: [
                    if (arhiviranIzBaze)
                      IconButton(
                        icon: Icon(Icons.delete_forever, color: boje.A),
                        onPressed: () => _obrisiChatOdmah(boje),
                      ),
                  ],
                  title: _buildAppBarTitle(boje),
                ),
          body: PozadinaKrugovi(
            krugBoja: boje.C,
            child: SafeArea(
              child: jeWeb
                  ? _buildWebView(boje, isDark, arhiviranIzBaze)
                  : _buildMobileView(boje, arhiviranIzBaze),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebView(
    QuickJobsColors boje,
    bool isDark,
    bool arhiviranIzBaze,
  ) {
    final Color boxPozadina = isDark
        ? (boje.A ?? Colors.black).withValues(alpha: 0.08)
        : (boje.A ?? Colors.black).withValues(alpha: 0.10);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
          decoration: BoxDecoration(
            color: arhiviranIzBaze
                ? (boje.B ?? boje.C)?.withValues(alpha: 1.0)
                : (boje.C ?? boje.B)?.withValues(alpha: 1.0),
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
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => KorisnickiProfil(
                      prikazaniKorisnikId: widget.sugovornikId,
                    ),
                  ),
                ),
                child: CircleAvatar(
                  backgroundColor: boje.bg,
                  child: Icon(Icons.person_outline, color: boje.A),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FutureBuilder<String>(
                      future: _chatService.dohvatiImeSugovornika(
                        widget.sugovornikId,
                      ),
                      builder: (context, snapshot) {
                        final ime = snapshot.data ?? widget.imeSugovornika;

                        return Text(
                          ime,
                          style: TextStyle(
                            color: boje.A,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                          overflow: TextOverflow.ellipsis,
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _navigirajNaOglas,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: boje.A,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          widget.naslovOglasa,
                          style: TextStyle(
                            color: boje.bg,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (arhiviranIzBaze)
                IconButton(
                  icon: Icon(Icons.delete_forever, color: boje.A),
                  tooltip: 'Obriši razgovor',
                  onPressed: () => _obrisiChatOdmah(boje),
                ),
            ],
          ),
        ),
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: Container(
                margin: const EdgeInsets.all(24),
                clipBehavior: Clip.antiAlias,
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
                    Expanded(
                      child: Opacity(
                        opacity: arhiviranIzBaze ? 0.6 : 1.0,
                        child: _buildMessagesStream(boje),
                      ),
                    ),
                    arhiviranIzBaze
                        ? _buildArhiviranBanner(boje)
                        : _buildInputArea(arhiviranIzBaze, boje),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileView(QuickJobsColors boje, bool arhiviranIzBaze) {
    return Column(
      children: [
        Expanded(
          child: Opacity(
            opacity: arhiviranIzBaze ? 0.6 : 1.0,
            child: _buildMessagesStream(boje),
          ),
        ),
        arhiviranIzBaze
            ? _buildArhiviranBanner(boje)
            : _buildInputArea(arhiviranIzBaze, boje),
      ],
    );
  }

  Widget _buildAppBarTitle(QuickJobsColors boje) {
    return Row(
      children: [
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Icons.arrow_back_ios_new, color: boje.A, size: 22),
        ),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  KorisnickiProfil(prikazaniKorisnikId: widget.sugovornikId),
            ),
          ),
          child: CircleAvatar(
            backgroundColor: boje.bg,
            child: Icon(Icons.person_outline, color: boje.A),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FutureBuilder<String>(
                future: _chatService.dohvatiImeSugovornika(widget.sugovornikId),
                builder: (context, snapshot) {
                  final ime = snapshot.data ?? widget.imeSugovornika;

                  return Text(
                    ime,
                    style: TextStyle(
                      color: boje.A,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  );
                },
              ),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: _navigirajNaOglas,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: boje.A,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    widget.naslovOglasa,
                    style: TextStyle(
                      color: boje.bg,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMessagesStream(QuickJobsColors boje) {
    return StreamBuilder<List>(
      stream: _chatService.pratiPoruke(widget.sobaId),
      builder: (context, snapshot) {
        final poruke = snapshot.data ?? [];

        return ListView.builder(
          reverse: true,
          padding: const EdgeInsets.all(16),
          itemCount: poruke.length,
          itemBuilder: (context, index) => _buildChatBubble(
            poruke[index]['tekst'],
            poruke[index]['created_at'],
            poruke[index]['posiljatelj_id'] == mojId,
            boje,
          ),
        );
      },
    );
  }

  Widget _buildArhiviranBanner(QuickJobsColors boje) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 25, horizontal: 20),
      decoration: BoxDecoration(
        color: boje.C?.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: boje.A!.withValues(alpha: 0.2))),
      ),
      child: Column(
        children: [
          Icon(
            Icons.lock_clock_outlined,
            color: boje.A?.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 8),
          Text(
            "Razgovor je arhiviran jer je posao završen.",
            style: TextStyle(fontWeight: FontWeight.bold, color: boje.A),
          ),
          Text(
            "Slanje poruka više nije moguće.",
            style: TextStyle(
              fontSize: 12,
              color: boje.A?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool zakljucano, QuickJobsColors boje) {
    return Container(
      padding: const EdgeInsets.all(12),
      color: boje.C,
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _porukaController,
                enabled: !zakljucano,
                style: TextStyle(color: boje.A),
                onSubmitted: (_) => _posaljiPoruku(zakljucano),
                decoration: InputDecoration(
                  hintText: "Upišite poruku...",
                  hintStyle: TextStyle(color: boje.A?.withValues(alpha: 0.5)),
                  fillColor: boje.bg,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(25),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: boje.A,
              child: IconButton(
                onPressed: () => _posaljiPoruku(zakljucano),
                icon: Icon(Icons.send, color: boje.bg, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatBubble(
    String tekst,
    String vrijeme,
    bool ja,
    QuickJobsColors boje,
  ) {
    final formatirano = DateFormat('HH:mm').format(DateTime.parse(vrijeme));

    return Align(
      alignment: ja ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: ja ? boje.C : boje.B,
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(tekst, style: TextStyle(fontSize: 15, color: boje.A)),
            const SizedBox(height: 4),
            Text(
              formatirano,
              style: TextStyle(
                fontSize: 10,
                color: boje.A?.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}