import 'app_settings.dart';

/// Picks the Portuguese or English variant of a string.
String tr(String pt, String en) => AppSettings.instance.isEn ? en : pt;

/// UI strings (everything that isn't portfolio content).
class S {
  S._();

  static List<String> get sections => [
        'HOME',
        'STATUS',
        tr('MISSÕES', 'QUESTS'),
        tr('FASES', 'STAGES'),
        tr('CONTATO', 'CONTACT'),
      ];

  static String get achievementEnd => tr(
        '🏆 CONQUISTA DESBLOQUEADA:\nChegou até o fim da run!',
        '🏆 ACHIEVEMENT UNLOCKED:\nYou reached the end of the run!',
      );
  static String get konami => tr('🎮 KONAMI CODE! +100 XP', '🎮 KONAMI CODE! +100 XP');
  static String get easterEgg => tr(
        '👀 ACHOU O EASTER EGG ESCONDIDO!',
        '👀 YOU FOUND THE HIDDEN EASTER EGG!',
      );
  static String get lampOn => tr(
        '💡 CONQUISTA: Fez-se a luz!',
        '💡 ACHIEVEMENT: Let there be light!',
      );
  static String get lampOff => tr(
        '🌙 CONQUISTA: Modo furtivo ativado!',
        '🌙 ACHIEVEMENT: Stealth mode on!',
      );
  static String get bookFlip => tr(
        '📖 CONQUISTA: Poliglota! Idioma alterado.',
        '📖 ACHIEVEMENT: Polyglot! Language changed.',
      );

  static String get lampTooltip => tr('Puxe a cordinha: tema claro/escuro',
      'Pull the chain: light/dark theme');
  static String get bookTooltip =>
      tr('Folheie o livro: idioma', 'Flip the book: language');

  // Wizard
  static String get wizardName => tr('MAGO', 'WIZARD');
  static String get wizardHint => tr(
        'Que tal roubar o café ou o cajado do mago?',
        "How about stealing the wizard's coffee or staff?",
      );
  static String get wizardCoffee => tr(
        'Tire tudo de mim, menos meu café!',
        'Take everything from me, but not my coffee!',
      );
  static String get wizardStaff => tr(
        'Um mago não é dependente de suas ferramentas, ele que as cria.',
        'A wizard is not dependent on his tools, he creates them.',
      );

  // Hero
  static String get heroKicker =>
      tr('INSIRA A FICHA PARA CONTINUAR', 'INSERT COIN TO CONTINUE');
  static String get heroBio => tr(
        'Sou desenvolvedor mobile há mais de 4 anos, com passagem por '
            'Android nativo, iOS e Flutter — incluindo uma temporada '
            'internacional em um time global. Já entreguei produtos do '
            'zero até a loja, como o Servirologia, hoje com mais de 1 '
            'milhão de usuários. Atualmente em busca de uma posição de '
            'Mobile Developer Pleno.',
        "I've been a mobile developer for over 4 years, with experience in "
            'native Android, iOS and Flutter — including an international '
            "stint on a global team. I've shipped products from scratch to "
            'the store, like Servirologia, now with over 1 million users. '
            'Currently looking for a Mid-level Mobile Developer position.',
      );
  static String get pressStart => tr('▶ PRESS START', '▶ PRESS START');

  // Status
  static String get statusKicker => tr('FICHA DO JOGADOR', 'PLAYER SHEET');
  static String get statusNote => tr(
        '* Os níveis são só pra deixar o clima mais divertido — na vida '
            'real sempre aparece um chefe novo pela frente.',
        '* Levels are just for fun — in real life a new boss always shows '
            'up ahead.',
      );

  // Missions
  static String get missionsKicker => tr('LOG DE MISSÕES', 'QUEST LOG');
  static String get missionsTitle => tr('ONDE JÁ JOGUEI', "WHERE I'VE PLAYED");
  static String get missionsHint => tr(
        'Toque em cada missão pra ver os detalhes.',
        'Tap each quest to see the details.',
      );

  // Stages
  static String get stagesKicker => tr('MAPA DE FASES', 'STAGE MAP');
  static String get stagesTitle =>
      tr('SELECIONE SUA FASE', 'SELECT YOUR STAGE');
  static String get stagesHint => tr(
        'Arraste pro lado — projetos pessoais e alguns que ajudei a '
            'construir com outros times.',
        'Swipe sideways — personal projects and a few I helped build with '
            'other teams.',
      );

  // Contact
  static String get contactHint => tr('Bora trocar uma ideia.', "Let's chat.");
  static String get footer => tr(
        'Feito com Flutter de verdade e café. © 2026 Daniel Augusto.',
        'Made with real Flutter and coffee. © 2026 Daniel Augusto.',
      );
}
