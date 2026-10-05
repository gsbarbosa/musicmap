import 'package:flutter/material.dart';

/// Estado de disponibilidade do módulo no painel
enum DashboardModuleStatus {
  enabled,
  comingSoon,
}

/// Configuração de um card do dashboard (escalável / sem hardcode espalhado)
class DashboardModuleConfig {
  final String key;
  final String title;
  final String description;
  final IconData icon;
  final DashboardModuleStatus status;
  /// Rota relativa com `:profileId` quando [status] == enabled (ex. `/shows/:profileId`)
  final String routePattern;
  /// Ordem na jornada (1–4) só para módulos ativos; ajuda hierarquia visual na central
  final int? journeyStep;

  const DashboardModuleConfig({
    required this.key,
    required this.title,
    required this.description,
    required this.icon,
    required this.status,
    this.routePattern = '',
    this.journeyStep,
  });

  /// Módulos já disponíveis, na ordem da jornada: agenda → preparação → lançamentos
  static const List<DashboardModuleConfig> enabledInJourneyOrder = [
    DashboardModuleConfig(
      key: 'shows',
      title: 'Agendar shows',
      description:
          'Cadastre eventos, acompanhe confirmados e pendentes e mantenha o histórico — sua agenda de apresentações em um só lugar.',
      icon: Icons.event_rounded,
      status: DashboardModuleStatus.enabled,
      routePattern: '/shows',
      journeyStep: 1,
    ),
    DashboardModuleConfig(
      key: 'gigbag',
      title: 'GigBag',
      description:
          'Checklists para show, ensaio, gravação e viagem. Itens permanecem marcados até você resetar; duplique listas e use modelos.',
      icon: Icons.checklist_rounded,
      status: DashboardModuleStatus.enabled,
      routePattern: '/gigbag',
      journeyStep: 2,
    ),
    DashboardModuleConfig(
      key: 'tasks',
      title: 'Tarefas',
      description:
          'Pendências com responsável, prazo e prioridade. Vincule a shows, lançamentos ou checklists e acompanhe o que venceu no painel.',
      icon: Icons.task_alt_rounded,
      status: DashboardModuleStatus.enabled,
      routePattern: '/tasks',
      journeyStep: 3,
    ),
    DashboardModuleConfig(
      key: 'releases',
      title: 'Agendar lançamentos',
      description:
          'Planeje singles, EPs e álbuns com datas, status e marcos opcionais para equipe e divulgação.',
      icon: Icons.album_rounded,
      status: DashboardModuleStatus.enabled,
      routePattern: '/releases',
      journeyStep: 4,
    ),
  ];

  /// Ideias e expansões futuras — separadas na UI dos módulos ativos
  static const List<DashboardModuleConfig> roadmap = [
    DashboardModuleConfig(
      key: 'ai_mentor',
      title: 'Mentoria com IA',
      description:
          'Bio, legendas, ideias de conteúdo e posicionamento com apoio de IA — em breve no Music Map.',
      icon: Icons.auto_awesome_rounded,
      status: DashboardModuleStatus.comingSoon,
    ),
    DashboardModuleConfig(
      key: 'partnerships',
      title: 'Encontrar parcerias',
      description:
          'Conecte-se com artistas, produtores e espaços. Matchmaking e oportunidades — chegando em breve.',
      icon: Icons.handshake_rounded,
      status: DashboardModuleStatus.comingSoon,
    ),
    DashboardModuleConfig(
      key: 'network',
      title: 'Network',
      description:
          'Rede interna com descoberta e mensagens. Comunidade Music Map — em breve.',
      icon: Icons.groups_rounded,
      status: DashboardModuleStatus.comingSoon,
    ),
  ];

  /// Lista completa (jornada + roadmap), útil para contagens ou migrações
  static List<DashboardModuleConfig> get all => [
        ...enabledInJourneyOrder,
        ...roadmap,
      ];
}
