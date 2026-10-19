// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'l10n.dart';

// ignore_for_file: type=lint

/// The translations for Portuguese (`pt`).
class L10nPt extends L10n {
  L10nPt([String locale = 'pt']) : super(locale);

  @override
  String robotState(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c1': 'A arrancar',
      'c2': 'Fora da base',
      'c3': 'Parado',
      'c4': 'Comando manual',
      'c5': 'A limpar',
      'c6': 'A voltar à base',
      'c7': 'Modo manual',
      'c8': 'Na base',
      'c9': 'Problema a carregar',
      'c10': 'Em pausa',
      'c11': 'Limpeza localizada',
      'c12': 'Erro',
      'c13': 'A desligar',
      'c14': 'A atualizar',
      'c15': 'A estacionar',
      'c16': 'A ir para o destino',
      'c17': 'A limpar zona',
      'c18': 'A limpar divisões',
      'c22': 'A esvaziar o depósito',
      'c23': 'A lavar a mopa',
      'c25': 'A lavar a mopa',
      'c26': 'A ir lavar a mopa',
      'c29': 'A mapear',
      'c100': 'Carregado',
      'c101': 'Offline',
      'other': 'Estado',
    });
    return '$_temp0';
  }

  @override
  String fanLevel(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c101': 'silenciosa',
      'c102': 'equilibrada',
      'c103': 'turbo',
      'c104': 'máxima',
      'c108': 'máxima+',
      'c105': 'desligada',
      'c106': 'personalizada',
      'c110': 'inteligente',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String waterLevel(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c200': 'sem água',
      'c221': 'muito pouca',
      'c225': 'baixa',
      'c230': 'suave',
      'c235': 'média',
      'c240': 'moderada',
      'c245': 'alta',
      'c250': 'extrema',
      'other': '—',
    });
    return '$_temp0';
  }

  @override
  String robotErrorText(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c1': 'Laser bloqueado. Verifica se há algo a tapar o sensor no topo.',
      'c2': 'Para-choques preso. Toca-lhe para o libertar.',
      'c3': 'Rodas no ar. Põe o robô no chão.',
      'c4': 'Sensores de queda sujos ou bloqueados. Limpa-os.',
      'c5': 'Escova principal presa. Tira cabelos e fios.',
      'c6': 'Escova lateral presa.',
      'c7': 'Rodas presas.',
      'c8': 'O robô ficou encurralado. Liberta-o.',
      'c9': 'Falta o depósito do pó.',
      'c10': 'Filtro do depósito com problema.',
      'c12': 'Bateria fraca.',
      'c13': 'Erro a carregar. Limpa os contactos da base e do robô.',
      'c14': 'Erro na bateria.',
      'c15': 'Sensor de parede sujo.',
      'c16': 'Robô inclinado. Põe-no numa superfície plana.',
      'c17': 'Erro na escova lateral.',
      'c18': 'Erro no ventilador.',
      'c19': 'Problema com a base.',
      'c20': 'Sensor ótico sujo. Limpa-o.',
      'c21': 'Para-choques vertical pressionado.',
      'c22': 'Não encontra a base.',
      'c23': 'Não conseguiu voltar à base.',
      'c24': 'Está numa zona proibida.',
      'c25': 'Câmara suja ou bloqueada.',
      'c27': 'Mecanismo de elevação da mopa preso.',
      'c28': 'Robô em cima de um tapete com a mopa.',
      'c29': 'Filtro bloqueado. Limpa ou troca o filtro.',
      'c30': 'Parede virtual detetada.',
      'c31': 'Não consegue atravessar o tapete.',
      'c32': 'Erro interno. Reinicia o robô.',
      'c34': 'Erro no esvaziamento automático.',
      'c35': 'Erro no esvaziamento automático.',
      'c36': 'Problema no rolo da mopa.',
      'c37': 'Problema no rolo da mopa.',
      'c38': 'Depósito de água limpa vazio ou mal colocado.',
      'c39': 'Depósito de água suja cheio ou mal colocado.',
      'c40': 'Filtro do tabuleiro de lavagem entupido.',
      'c41': 'Depósito de água limpa com problema.',
      'c42': 'Escova de limpeza da base com problema.',
      'c43': 'Escova de limpeza da base com problema.',
      'c44': 'Filtro da base com problema.',
      'c45': 'Problema no rolo da mopa.',
      'c48': 'Problema a abastecer água.',
      'c49': 'Problema a escoar água.',
      'c51': 'Proteção de temperatura ativa. Espera que arrefeça.',
      'c52': 'Problema no tabuleiro de lavagem.',
      'c53': 'Tabuleiro de lavagem cheio de água.',
      'c54': 'Suporte da mopa caiu.',
      'c55': 'Verifica o tabuleiro de lavagem.',
      'c56': 'Erro de áudio.',
      'other': 'Erro $code.',
    });
    return '$_temp0';
  }

  @override
  String dockErrorText(String code) {
    String _temp0 = intl.Intl.selectLogic(code, {
      'c32': 'Falta o saco ou o filtro da base.',
      'c33': 'Erro no ventilador do esvaziamento.',
      'c34': 'Conduta do esvaziamento entupida.',
      'c35': 'Erro de tensão no esvaziamento.',
      'c38': 'Depósito de água limpa vazio.',
      'c39': 'Depósito de água suja cheio.',
      'c42': 'Escova de manutenção da base presa.',
      'c44': 'Tampa do depósito de água suja aberta.',
      'c46': 'Falta o depósito da base.',
      'c53': 'Tanque de limpeza cheio ou entupido.',
      'other': 'Erro da base $code.',
    });
    return '$_temp0';
  }

  @override
  String get alertRobotTitle => 'O robô precisa de ajuda';

  @override
  String get alertDockTitle => 'A base precisa de atenção';

  @override
  String get alertWaterTitle => 'Falta água';

  @override
  String get alertWaterBody => 'Enche o depósito de água limpa da base.';

  @override
  String get sectionCarpets => 'Tapetes';

  @override
  String get sectionDock => 'Base';

  @override
  String get sectionCleaning => 'Limpeza';

  @override
  String get sectionRobot => 'Robô';

  @override
  String get setCarpetMode => 'Com a mopa, nos tapetes';

  @override
  String get optAvoid => 'Evitar';

  @override
  String get optLiftMop => 'Levantar mopa';

  @override
  String get optIgnore => 'Ignorar';

  @override
  String get optCross => 'Atravessar';

  @override
  String get setCarpetBoost => 'Aumentar a sucção nos tapetes';

  @override
  String get setCarpetDeep => 'Limpeza profunda de tapetes';

  @override
  String get setAutoEmpty => 'Esvaziar o depósito automaticamente';

  @override
  String get setEmptyMode => 'Intensidade do esvaziamento';

  @override
  String get optSmart => 'Inteligente';

  @override
  String get optLight => 'Leve';

  @override
  String get optBalanced => 'Equilibrada';

  @override
  String get optMax => 'Máxima';

  @override
  String get optDeep => 'Profunda';

  @override
  String get optVeryDeep => 'Muito profunda';

  @override
  String get setDryer => 'Secar a mopa depois de lavar';

  @override
  String get setWashMode => 'Lavagem da mopa';

  @override
  String get setWashInterval => 'Voltar a lavar a mopa a cada';

  @override
  String get setWashIntervalSub => 'Durante a limpeza';

  @override
  String minutes(int n) {
    return '$n min';
  }

  @override
  String get setCornerMop => 'Estender a mopa nos cantos';

  @override
  String get setFurniture => 'Reconhecer mobília';

  @override
  String get setFurnitureSub => 'Limpa melhor à volta e por baixo de móveis';

  @override
  String get setLed => 'Luz dos botões';

  @override
  String get chAlerts => 'Avisos do robô';

  @override
  String get chAlertsDesc => 'Erros, problemas na base e falta de água';

  @override
  String get chCleans => 'Limpezas terminadas';

  @override
  String get chCleansDesc => 'Resumo de cada limpeza';

  @override
  String get chStatus => 'Estado do robô';

  @override
  String get chStatusDesc => 'O que o robô está a fazer e o que vem a seguir';

  @override
  String roomN(int id) {
    return 'Divisão $id';
  }

  @override
  String get robot => 'Robô';

  @override
  String get robotCharging => 'Robô a carregar';

  @override
  String get errNoLink => 'Sem ligação ao robô';

  @override
  String get errTimeout => 'O robô não respondeu a tempo. Tenta outra vez.';

  @override
  String get errUnsupported => 'O robô não suporta isto.';

  @override
  String get errRobot => 'O robô recusou o comando.';

  @override
  String get errAccountNotFound => 'Não encontrei nenhuma conta Roborock com este email.';

  @override
  String get errTooManyCodes => 'Pediste códigos demasiadas vezes. Tenta mais tarde.';

  @override
  String get errInvalidCode => 'Código inválido.';

  @override
  String get errAcceptTerms => 'Tens de aceitar os termos na app Roborock primeiro.';

  @override
  String get errSessionExpired => 'Sessão expirada. Faz login outra vez.';

  @override
  String get errNoHome => 'Sem casa associada à conta.';

  @override
  String get errNoInternet => 'Sem ligação à cloud Roborock.';

  @override
  String get errUnexpected => 'Algo correu mal. Tenta outra vez.';

  @override
  String get pauseNotStarted => 'O robô não arrancou a limpeza.';

  @override
  String pauseRobotError(String error) {
    return 'O robô parou com um erro: $error';
  }

  @override
  String get pauseStartFailed => 'Não consegui arrancar a próxima limpeza.';

  @override
  String get pauseInterrupted => 'A limpeza anterior foi interrompida. Continuo com o resto da fila?';

  @override
  String get outcomeFinished => 'Terminou';

  @override
  String get outcomeUnreachable => 'Área inacessível';

  @override
  String get outcomeLostLocation => 'Perdeu a localização';

  @override
  String get outcomeWashError => 'Erro na lavagem';

  @override
  String get outcomeInterrupted => 'Interrompida';

  @override
  String get sourceButton => 'Botão';

  @override
  String get sourceApp => 'App';

  @override
  String get sourceSchedule => 'Agendamento';

  @override
  String get sourceRoutine => 'Rotina';

  @override
  String get sourceVoice => 'Assistente de voz';

  @override
  String get sourceOther => 'Outro';

  @override
  String routineQueuedTitle(String name) {
    return 'Rotina \"$name\"';
  }

  @override
  String get routineQueuedBody => 'Posta na fila à hora marcada.';

  @override
  String get queuePaused => 'Fila em pausa';

  @override
  String jobZones(int count, String area) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count zonas', one: 'Zona');
    return '$_temp0 ($area m²)';
  }

  @override
  String get wholeHome => 'Casa toda';

  @override
  String cleaningRoom(String room) {
    return 'A limpar: $room';
  }

  @override
  String minutesLeft(int n) {
    return 'faltam ~$n min';
  }

  @override
  String batteryPercent(int n) {
    return 'bateria $n%';
  }

  @override
  String upNext(String job) {
    return 'a seguir: $job';
  }

  @override
  String get queuePausedLower => 'fila em pausa';

  @override
  String get cleanGeneric => 'Limpeza';

  @override
  String jobFinished(String job) {
    return '$job terminada';
  }

  @override
  String get cleanInterrupted => 'Limpeza interrompida';

  @override
  String jobOutcome(String job, String outcome) {
    return '$job: $outcome';
  }

  @override
  String minutesArea(int min, String area) {
    return '$min min · $area m²';
  }

  @override
  String mopWashes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lavagens da mopa',
      one: '1 lavagem da mopa',
    );
    return '$_temp0';
  }

  @override
  String cleanZonesTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Limpar $count áreas',
      one: 'Limpar esta área',
    );
    return '$_temp0';
  }

  @override
  String get zonesQueueNote => 'Entram na fila depois da limpeza atual, uma a seguir à outra. Nada é cancelado.';

  @override
  String get addToQueue => 'Pôr na fila';

  @override
  String get clean => 'Limpar';

  @override
  String get drawZoneHint => 'Arrasta o dedo no mapa para desenhar uma área. Podes desenhar várias.';

  @override
  String zonesArea(int count, String area) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count áreas', one: '1 área');
    return '$_temp0 · $area m²';
  }

  @override
  String get next => 'Seguinte';

  @override
  String get addZone => 'Adicionar área';

  @override
  String get zone => 'Área';

  @override
  String get cleanFinished => 'Limpeza terminada';

  @override
  String get connecting => 'A ligar ao robô…';

  @override
  String get cleaning => 'A limpar';

  @override
  String suctionLevel(String level) {
    return 'sucção $level';
  }

  @override
  String waterLevelLine(String level) {
    return 'água $level';
  }

  @override
  String get pause => 'Pausa';

  @override
  String get resume => 'Continuar';

  @override
  String get adjust => 'Ajustar';

  @override
  String get dock => 'Base';

  @override
  String get findMe => 'Onde estás?';

  @override
  String get cleanWholeHome => 'Limpar a casa toda';

  @override
  String get addToQueueLong => 'Adicionar à fila';

  @override
  String get adjustRunning => 'Ajustar a limpeza em curso';

  @override
  String get adjustRunningSub => 'Muda já, sem cancelar nada.';

  @override
  String get upNextTitle => 'A seguir';

  @override
  String get resumeQueue => 'Retomar fila';

  @override
  String nowJob(String job) {
    return 'Agora: $job';
  }

  @override
  String get cancel => 'Cancelar';

  @override
  String get skipToNext => 'Saltar para a próxima';

  @override
  String get stopping => 'A parar…';

  @override
  String get skip => 'Saltar';

  @override
  String get removeFromQueue => 'Tirar da fila';

  @override
  String get notifications => 'Notificações';

  @override
  String get now => 'Agora';

  @override
  String get recent => 'Recentes';

  @override
  String get noAlertsYet => 'Ainda sem avisos.';

  @override
  String get linkLocal => 'Ligado pela rede local';

  @override
  String get linkCloud => 'Ligado pela cloud';

  @override
  String get linkOffline => 'Sem ligação';

  @override
  String get fanMopOnly => 'Só mopa';

  @override
  String get fanQuiet => 'Silenciosa';

  @override
  String get fanBalanced => 'Equilibrada';

  @override
  String get fanTurbo => 'Turbo';

  @override
  String get fanMax => 'Máxima';

  @override
  String get fanMaxPlus => 'Máx+';

  @override
  String get waterOff => 'Sem água';

  @override
  String get waterLow => 'Baixa';

  @override
  String get waterMedium => 'Média';

  @override
  String get waterHigh => 'Alta';

  @override
  String get waterExtreme => 'Extrema';

  @override
  String get routeFast => 'Rápida';

  @override
  String get routeStandard => 'Padrão';

  @override
  String get routeDeepPlus => 'Profunda+';

  @override
  String get styleSmart => 'Inteligente';

  @override
  String get styleVacuum => 'Aspirar';

  @override
  String get styleVacuumMop => 'Aspirar e esfregar';

  @override
  String get styleVacuumThenMop => 'Aspirar e depois esfregar';

  @override
  String get styleMop => 'Só esfregar';

  @override
  String get styleCustom => 'Personalizado';

  @override
  String get sumSmart => 'inteligente';

  @override
  String get sumVacuumThenMop => 'aspirar e depois esfregar';

  @override
  String get sumMopOnly => 'só mopa';

  @override
  String sumVacuum(String level) {
    return 'aspirar $level';
  }

  @override
  String sumMop(String level) {
    return 'mopa $level';
  }

  @override
  String sumRoute(String route) {
    return 'rota $route';
  }

  @override
  String get smartHint => 'O robô ajusta sucção, água e percurso ao piso e à sujidade de cada zona.';

  @override
  String get suction => 'Sucção';

  @override
  String get mop => 'Mopa';

  @override
  String get mopRoute => 'Rota da mopa';

  @override
  String get passes => 'Passagens';

  @override
  String get passOne => 'Uma';

  @override
  String get passTwo => 'Duas';

  @override
  String get passThree => 'Três';

  @override
  String get modeRooms => 'Divisões';

  @override
  String get modeZones => 'Áreas';

  @override
  String get modePoint => 'Ir até';

  @override
  String get modeHome => 'Casa toda';

  @override
  String get hintRooms => 'Toca nas divisões pela ordem em que as queres limpas.';

  @override
  String get hintZones => 'Arrasta o dedo no mapa para desenhar áreas.';

  @override
  String get hintPoint => 'Toca no sítio para onde o robô deve ir.';

  @override
  String get hintHome => 'Limpa a casa toda pela ordem que o robô achar melhor.';

  @override
  String get howToClean => 'Como limpar';

  @override
  String get appliesToAllRooms => 'Aplica-se a todas as divisões escolhidas.';

  @override
  String get roomOnlySettings => 'Definições só para esta divisão.';

  @override
  String routineSummary(int count, String when) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count pedidos', one: '1 pedido');
    return '$_temp0 · $when';
  }

  @override
  String get joinsQueueNoCancel => 'entra na fila sem cancelar a limpeza atual';

  @override
  String get startsNow => 'arranca já';

  @override
  String get cleanNow => 'Limpar agora';

  @override
  String get newRoutine => 'Nova rotina';

  @override
  String get routine => 'Rotina';

  @override
  String get name => 'Nome';

  @override
  String get repeat => 'Repetir';

  @override
  String get weekdaysNarrow => 'S T Q Q S S D';

  @override
  String atTime(String time) {
    return 'Às $time';
  }

  @override
  String get unscheduled => 'Sem horário (só à mão)';

  @override
  String get time => 'Hora';

  @override
  String get changeTime => 'Mudar hora';

  @override
  String get enabled => 'Ligada';

  @override
  String get save => 'Guardar';

  @override
  String get deleteRoutine => 'Apagar rotina';

  @override
  String get pickRoomsOnMap => 'Escolhe divisões no mapa';

  @override
  String cleanRooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Limpar $count divisões',
      one: 'Limpar 1 divisão',
    );
    return '$_temp0';
  }

  @override
  String queueRooms(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pôr $count divisões na fila',
      one: 'Pôr 1 divisão na fila',
    );
    return '$_temp0';
  }

  @override
  String get drawZoneOnMap => 'Desenha uma área no mapa';

  @override
  String cleanZones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Limpar $count áreas',
      one: 'Limpar 1 área',
    );
    return '$_temp0';
  }

  @override
  String queueZones(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Pôr $count áreas na fila',
      one: 'Pôr 1 área na fila',
    );
    return '$_temp0';
  }

  @override
  String get tapPointOnMap => 'Toca num ponto do mapa';

  @override
  String get goHere => 'Ir até aqui';

  @override
  String get queueWholeHome => 'Pôr a casa toda na fila';

  @override
  String get plan => 'Planear';

  @override
  String runRoutine(String name) {
    return 'Correr rotina $name';
  }

  @override
  String get undoLastZone => 'Desfazer a última área';

  @override
  String get how => 'Como';

  @override
  String get saveAsRoutine => 'Guardar como rotina';

  @override
  String get clearSelection => 'Limpar seleção';

  @override
  String settingsOf(String name) {
    return 'Definições de $name';
  }

  @override
  String get consMainBrush => 'Escova\nprincipal';

  @override
  String get consSideBrush => 'Escova\nlateral';

  @override
  String get consFilter => 'Filtro';

  @override
  String get consSensors => 'Sensores';

  @override
  String get startsAt => 'Começa às';

  @override
  String get endsAt => 'Acaba às';

  @override
  String resetPart(String name) {
    return 'Repor $name?';
  }

  @override
  String get resetPartSub => 'Faz isto depois de trocares ou limpares a peça.';

  @override
  String get reset => 'Repor';

  @override
  String stateBattery(String state, int n) {
    return '$state · bateria $n%';
  }

  @override
  String get connectingShort => 'A ligar…';

  @override
  String get emptyBin => 'Esvaziar depósito';

  @override
  String get washMop => 'Lavar mopa';

  @override
  String get map => 'Mapa';

  @override
  String get editMap => 'Editar mapa';

  @override
  String get editMapSub => 'Zonas proibidas, zonas sem mopa e paredes virtuais';

  @override
  String get maintenance => 'Manutenção';

  @override
  String get cleanNowShort => 'limpar já';

  @override
  String hours(int n) {
    return '$n h';
  }

  @override
  String get gaugeHint => 'Toca num mostrador depois de limpares ou trocares a peça.';

  @override
  String currentValue(int value) {
    return 'Atual ($value)';
  }

  @override
  String get doNotDisturb => 'Não incomodar';

  @override
  String get quietAtNight => 'Silêncio à noite';

  @override
  String get quietAtNightSub => 'Não arranca limpezas nem fala';

  @override
  String get from => 'Das';

  @override
  String get to => 'às';

  @override
  String get soundSafety => 'Som e segurança';

  @override
  String get voiceVolume => 'Volume da voz';

  @override
  String get childLock => 'Bloqueio para crianças';

  @override
  String get childLockSub => 'Desativa os botões do robô';

  @override
  String get appearance => 'Aparência';

  @override
  String get theme => 'Tema';

  @override
  String get themeSystem => 'Automático';

  @override
  String get themeLight => 'Claro';

  @override
  String get themeDark => 'Escuro';

  @override
  String get logOut => 'Sair da conta';

  @override
  String durationMin(int m) {
    return '$m min';
  }

  @override
  String durationHourMin(int h, int m) {
    return '$h h $m min';
  }

  @override
  String todayAt(String time) {
    return 'Hoje, $time';
  }

  @override
  String yesterdayAt(String time) {
    return 'Ontem, $time';
  }

  @override
  String dateAt(DateTime date, String time) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString, $time';
  }

  @override
  String get history => 'Histórico';

  @override
  String get historySub => 'O que o robô fez e quanto demorou';

  @override
  String get last7Days => 'Últimos 7 dias';

  @override
  String get cleansUnit => 'limpezas';

  @override
  String get timeLabel => 'Tempo';

  @override
  String get in7Days => 'em 7 dias';

  @override
  String get areaLabel => 'Área';

  @override
  String get m2In7Days => 'm² em 7 dias';

  @override
  String allTime(int count, int hours, int area) {
    return 'Desde sempre: $count limpezas · $hours h · $area m²';
  }

  @override
  String get perRoom => 'Por divisão';

  @override
  String get perRoomSub => 'Medido pela app durante as limpezas que acompanhou.';

  @override
  String roomStats(int count, String duration) {
    return '$count× · média $duration';
  }

  @override
  String get cleans => 'Limpezas';

  @override
  String get noRecordsYet => 'Ainda sem registos.';

  @override
  String washes(int count) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count lavagens', one: '1 lavagem');
    return '$_temp0';
  }

  @override
  String obstaclesAvoided(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count obstáculos evitados',
      one: '1 obstáculo evitado',
    );
    return '$_temp0';
  }

  @override
  String fasterThanAvg(int m) {
    return '$m min mais rápida que a média destas divisões';
  }

  @override
  String slowerThanAvg(int m) {
    return '$m min mais lenta que a média destas divisões';
  }

  @override
  String get omissionNote => 'O robô assinalou zonas que ficaram por limpar.';

  @override
  String get activity => 'Atividade';

  @override
  String get days14 => '14 dias';

  @override
  String get weeks8 => '8 semanas';

  @override
  String weekOf(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return 'Semana de $dateString';
  }

  @override
  String shortDate(DateTime date) {
    final intl.DateFormat dateDateFormat = intl.DateFormat.Md(localeName);
    final String dateString = dateDateFormat.format(date);

    return '$dateString';
  }

  @override
  String get noCleans => 'sem limpezas';

  @override
  String activityDetail(int count, int min, String area) {
    String _temp0 = intl.Intl.pluralLogic(count, locale: localeName, other: '$count limpezas', one: '1 limpeza');
    return '$_temp0 · $min min · $area m²';
  }

  @override
  String get recordMapGone =>
      'O robô já não tem o mapa desta limpeza. A partir de agora a app guarda o mapa de cada limpeza no telemóvel, para o poderes ver sempre.';

  @override
  String get toolNoGo => 'Proibida';

  @override
  String get toolNoGoHint => 'Arrasta para marcar onde o robô não pode entrar. Toca numa para a apagar.';

  @override
  String get toolNoMop => 'Sem mopa';

  @override
  String get toolNoMopHint => 'Arrasta para marcar onde aspira mas não esfrega. Toca numa para a apagar.';

  @override
  String get toolWall => 'Parede';

  @override
  String get toolWallHint => 'Arrasta uma linha que o robô não atravessa. Toca numa para a apagar.';

  @override
  String get saveNotShownYet =>
      'O robô aceitou, mas o mapa ainda não mostra as alterações. Tenta outra vez daqui a pouco.';

  @override
  String restrictions(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count restrições',
      one: '1 restrição',
      zero: 'Sem restrições',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Desfazer';

  @override
  String get deleteAll => 'Apagar todas';

  @override
  String get saveToRobot => 'Guardar no robô';

  @override
  String get noChanges => 'Sem alterações';

  @override
  String get errNoRobots => 'A conta não tem robôs.';

  @override
  String get loginPitch =>
      'Tudo o que a app oficial faz, e o que lhe falta: fila de limpezas, ajustes sem cancelar, mapa claro. Entra com a tua conta Roborock.';

  @override
  String get emailHint => 'o-teu@email.com';

  @override
  String get codeHint => 'código do email';

  @override
  String get signIn => 'Entrar';

  @override
  String get sendCode => 'Enviar código';

  @override
  String get changeEmail => 'Mudar de email';

  @override
  String get sending => 'A enviar…';

  @override
  String get loading => 'A carregar';

  @override
  String get choose => 'Escolher';

  @override
  String get tabNow => 'Agora';

  @override
  String get tabPlan => 'Planear';

  @override
  String get tabHistory => 'Histórico';

  @override
  String get tabRobot => 'Robô';

  @override
  String get setDryTime => 'Tempo de secagem';

  @override
  String get setWaterTemp => 'Água da lavagem da mopa';

  @override
  String get tempRoom => 'Temperatura ambiente';

  @override
  String get tempWarm => 'Morna';

  @override
  String get tempHot => 'Quente';
}
