import '../state/strings.dart';

/// A single skill/status bar shown on the "STATUS" screen.
class SkillStat {
  final String name;
  final int level;
  final double progress; // 0..1, purely for flavor
  const SkillStat(this.name, this.level, this.progress);
}

/// One professional experience entry shown in the "quest log".
class Quest {
  final String company;
  final String role;
  final String period;
  final String summary;
  final List<String> details;
  final List<String> tags;

  const Quest({
    required this.company,
    required this.role,
    required this.period,
    required this.summary,
    required this.details,
    required this.tags,
  });
}

/// A link/button that opens an external URL.
class LinkAction {
  final String label;
  final String url;
  const LinkAction(this.label, this.url);
}

/// A personal/professional project shown as a "stage" in the carousel.
class Stage {
  final String number;
  final String title;
  final List<String> tags;
  final String description;
  final bool isBoss;
  final List<LinkAction> actions;

  const Stage({
    required this.number,
    required this.title,
    required this.tags,
    required this.description,
    this.isBoss = false,
    required this.actions,
  });
}

List<SkillStat> get skills => [
  const SkillStat('Flutter & Dart', 27, 0.92),
  const SkillStat('Kotlin & Jetpack Compose', 26, 0.85),
  const SkillStat('Swift', 16, 0.55),
  const SkillStat('Clean Architecture & MVVM', 30, 0.95),
  const SkillStat('Firebase & Cloud', 21, 0.70),
  SkillStat(tr('Testes automatizados', 'Automated testing'), 18, 0.62),
];

List<Quest> get quests => [
  Quest(
    company: 'Karrera AI',
    role: tr('Engenheiro Web & Mobile', 'Web & Mobile Engineer'),
    period: tr('12/2024 — atual', '12/2024 — present'),
    summary: tr(
      'Ajudo a construir o produto do zero: do app mobile até o agente de IA '
          'que conversa com o usuário.',
      'I help build the product from scratch: from the mobile app to the AI '
          'agent that talks to the user.',
    ),
    details: [
      tr(
        'Trabalho na configuração das apps em Flutter e na integração com o '
            'back-end.',
        'I work on setting up the Flutter apps and integrating them with the '
            'back end.',
      ),
      tr(
        'Liderei a migração do chat com IA pra uma infraestrutura mais robusta '
            'na nuvem, com um agente que mantém o contexto da conversa.',
        'I led the migration of the AI chat to a more robust cloud '
            'infrastructure, with an agent that keeps the conversation '
            'context.',
      ),
      tr(
        'Entreguei features centrais do produto, como perfil de usuário, '
            'geração automática de currículo e rede profissional — além de '
            'autenticação, notificações e testes de performance.',
        'I shipped core product features such as user profile, automatic '
            'résumé generation and a professional network — plus '
            'authentication, notifications and performance testing.',
      ),
    ],
    tags: ['Flutter', 'Next.js', 'Google ADK', 'Firebase'],
  ),
  Quest(
    company: 'T2S Tecnologia',
    role: tr(
      'Mobile Software Engineer (LodgeLink, Calgary)',
      'Mobile Software Engineer (LodgeLink, Calgary)',
    ),
    period: '05/2026 — 07/2026',
    summary: tr(
      'Uma temporada internacional: entrei em um time 100% em inglês pra '
          'ajudar a construir o app da LodgeLink em Android nativo.',
      'An international stint: I joined a 100% English-speaking team to help '
          'build the LodgeLink app in native Android.',
    ),
    details: [
      tr(
        'Criei mais de 10 componentes reutilizáveis de design system e ajudei '
            'a padronizar o visual do app.',
        'I created 10+ reusable design system components and helped '
            'standardize the look of the app.',
      ),
      tr(
        'Refiz o fluxo de paginação de viagens pra evitar bugs de concorrência '
            'e trabalhei lado a lado com o time de iOS pra manter os dois apps '
            'consistentes.',
        'I reworked the trip pagination flow to avoid concurrency bugs and '
            'worked side by side with the iOS team to keep both apps '
            'consistent.',
      ),
    ],
    tags: ['Kotlin', 'Jetpack Compose', 'Design System'],
  ),
  Quest(
    company: 'Electric Spark',
    role: tr('Consultor e Engenheiro Mobile', 'Consultant & Mobile Engineer'),
    period: '09/2024 — 12/2024',
    summary: tr(
      'Aqui eu era consultor e desenvolvedor ao mesmo tempo: conversava '
          'direto com o cliente sobre o negócio e depois ia pro código.',
      'I was consultant and developer at the same time: I talked directly '
          'with the client about the business and then went to the code.',
    ),
    details: [
      tr(
        'Levantei requisitos com o cliente, publiquei o app nas duas lojas e '
            'ajudei o time com boas práticas de interface e performance.',
        'I gathered requirements with the client, published the app on both '
            'stores and helped the team with UI and performance best '
            'practices.',
      ),
    ],
    tags: ['Android', 'iOS', 'Clean Code'],
  ),
  Quest(
    company: 'Scale AI',
    role: tr(
      'Engenheiro de Software para Treinamento de IA',
      'Software Engineer for AI Training',
    ),
    period: '05/2024 — 09/2024',
    summary: tr(
      'Passei uns meses avaliando código de outras pessoas pra ajudar a '
          'treinar modelos de IA.',
      "I spent a few months evaluating other people's code to help train AI "
          'models.',
    ),
    details: [
      tr(
        'Revisei submissões em Dart, Flutter, Java, Python e JavaScript, '
            'elevando o padrão de qualidade aceito no processo.',
        'I reviewed submissions in Dart, Flutter, Java, Python and '
            'JavaScript, raising the quality bar accepted in the process.',
      ),
    ],
    tags: ['Dart', 'Python', 'Java'],
  ),
  Quest(
    company: 'Dopster Consultoria',
    role: tr('Dev Mobile → Front-End', 'Mobile Dev → Front-End'),
    period: '05/2022 — 04/2024',
    summary: tr(
      'Comecei como estagiário de front-end e saí de lá como líder técnico '
          'de um pequeno time mobile.',
      'I started as a front-end intern and left as tech lead of a small '
          'mobile team.',
    ),
    details: [
      tr(
        'Lancei um MVP do zero até a Google Play em 2 meses, construí um app '
            'de gestão de clínicas lidando com dados sensíveis, e antes disso '
            'corrigi boa parte dos bugs de uma aplicação em React.',
        'I launched an MVP from scratch to Google Play in 2 months, built a '
            'clinic management app handling sensitive data, and before that '
            'fixed a good share of the bugs in a React application.',
      ),
    ],
    tags: ['Flutter', 'React', 'Scrum'],
  ),
];

List<String> get sideQuests => [
  tr('🎮 Jogos', '🎮 Games'),
  tr('🥊 Boxe', '🥊 Boxing'),
  tr('📺 Animes', '📺 Anime'),
  '🧠 Leetcode',
  tr('📚 Estudos', '📚 Studying'),
];

List<Stage> get stages => [
  Stage(
    number: tr('FASE 1 · BOSS', 'STAGE 1 · BOSS'),
    title: 'Servirologia',
    tags: [tr('Rede social', 'Social network'), 'Flutter', tr('1M+ usuários', '1M+ users')],
    description: tr(
      'App que recompensa quem compartilha informação verdadeira e útil '
          'com a comunidade. Publicado nas duas lojas, com mais de 1 milhão de '
          'usuários — atuei no desenvolvimento junto com o time.',
      'App that rewards people who share true, useful information with the '
          'community. Published on both stores with over 1 million users — I '
          'worked on its development together with the team.',
    ),
    isBoss: true,
    actions: const [
      LinkAction(
        'Google Play',
        'https://play.google.com/store/apps/details?id=net.itsnoon.mobile.itsnoon&hl=pt_BR&pli=1',
      ),
      LinkAction(
        'App Store',
        'https://apps.apple.com/br/app/sevirologia/id1471439609',
      ),
    ],
  ),
  Stage(
    number: tr('FASE 2', 'STAGE 2'),
    title: 'Quiz Technical App',
    tags: const ['Flutter', 'Clean Arch', 'Python'],
    description: tr(
      'App de estudo estilo Duolingo pra treinar entrevista técnica '
          'mobile: pipeline em Python gera o banco de questões e o app roda o '
          'quiz offline-first, com repetição espaçada, streak e XP.',
      'Duolingo-style study app to practice mobile technical interviews: a '
          'Python pipeline generates the question bank and the app runs the '
          'quiz offline-first, with spaced repetition, streaks and XP.',
    ),
    actions: const [
      LinkAction('GitHub', 'https://github.com/danielrgb23/quiz_technical_app'),
    ],
  ),
  Stage(
    number: tr('FASE 3', 'STAGE 3'),
    title: 'Nest Firebase Notifications',
    tags: const ['NestJS', 'Firebase', 'Clean Arch'],
    description: tr(
      'Serviço de push notifications com Firebase Cloud Messaging em '
          'NestJS seguindo Clean Architecture — envio individual, por tópico '
          'ou em massa.',
      'Push notification service using Firebase Cloud Messaging in NestJS '
          'following Clean Architecture — individual, topic-based or bulk '
          'sending.',
    ),
    actions: const [
      LinkAction(
        'GitHub',
        'https://github.com/danielrgb23/nest_firebase_notifications',
      ),
    ],
  ),
  Stage(
    number: tr('FASE 4', 'STAGE 4'),
    title: tr('To Do List — Teste Fibbo', 'To Do List — Fibbo Test'),
    tags: const ['Flutter', 'Firebase'],
    description: tr(
      'Teste técnico pra Fibbo (3Wings): lista de tarefas com login como '
          'convidado ou conta, backup e recuperação na nuvem, e testes '
          'automatizados com Mockito.',
      'Technical test for Fibbo (3Wings): to-do list with guest or account '
          'login, cloud backup and recovery, and automated tests with '
          'Mockito.',
    ),
    actions: const [
      LinkAction(
        'GitHub',
        'https://github.com/danielrgb23/to_do_list_test_fibbo',
      ),
    ],
  ),
  Stage(
    number: tr('FASE 5', 'STAGE 5'),
    title: 'Ilia Movies',
    tags: const ['Flutter', 'Bloc', 'Clean Arch'],
    description: tr(
      'Desafio técnico pra ília digital: app de filmes com injeção de '
          'dependência, Bloc pro gerenciamento de estado e testes com '
          'Mockito.',
      'Technical challenge for ília digital: movie app with dependency '
          'injection, Bloc for state management and Mockito tests.',
    ),
    actions: const [
      LinkAction(
        'GitHub',
        'https://github.com/danielrgb23/ilia-flutter-challenge',
      ),
    ],
  ),
];

const contactLinks = <LinkAction>[
  LinkAction('GitHub', 'https://github.com/danielrgb23'),
  LinkAction('LinkedIn', 'https://linkedin.com/in/daniel-jasmelino'),
  LinkAction('Blog', 'https://daniel-jasmelino.hashnode.dev'),
  LinkAction('Instagram', 'https://www.instagram.com/daniel.jasmelino/'),
  LinkAction('Google Dev', 'https://g.dev/daniel-jasmelino'),
  LinkAction('E-mail', 'mailto:daniel.augusto.jasmelino@gmail.com'),
];
