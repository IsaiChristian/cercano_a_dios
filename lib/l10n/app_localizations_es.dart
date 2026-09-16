// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appName => 'Cercano a Dios';

  @override
  String get welcomeTitle => 'Cercano\na Dios';

  @override
  String get welcomeBody =>
      'Haz un poco de espacio para orar.\nDa gracias. Habla desde el corazón.\nRegresa mañana.';

  @override
  String get onboardingTagline => 'Un poco más cerca, cada día';

  @override
  String get onboardingTitle => 'Haz espacio\npara Dios.';

  @override
  String get onboardingSubtitle =>
      'Un momento de calma. Un corazón agradecido. Un nuevo comienzo.';

  @override
  String get onboardingPrivacy =>
      'Un compañero católico de oración privado. Tu voz y tu camino permanecen en este dispositivo.';

  @override
  String get beginJourney => 'Comenzar mi camino';

  @override
  String get today => 'Hoy';

  @override
  String get alarms => 'Alarmas';

  @override
  String get journal => 'Diario';

  @override
  String get settings => 'Ajustes';

  @override
  String get language => 'Idioma';

  @override
  String get english => 'Inglés';

  @override
  String get spanish => 'Español';

  @override
  String get milestones => 'Tus logros';

  @override
  String get beginMoment => 'Comenzar un momento';

  @override
  String get yourRhythm => 'Tu ritmo';

  @override
  String dayStreak(int count) {
    return 'Racha de $count día';
  }

  @override
  String daysStreak(int count) {
    return 'Racha de $count días';
  }

  @override
  String get view => 'Ver';

  @override
  String get todayComplete => 'Hoy hiciste tiempo para orar.';

  @override
  String get todayIncomplete =>
      'Un pequeño momento es suficiente para comenzar.';

  @override
  String weekProgress(int count) {
    return '$count de 7 días esta semana';
  }

  @override
  String get gentleInvitation => 'Una invitación amable';

  @override
  String get makePrayerPart => 'Haz espacio para la oración en tu día.';

  @override
  String get setFirstAlarm => 'Configurar mi primera alarma';

  @override
  String get manageAlarms => 'Administrar mis alarmas';

  @override
  String get moreWays => 'Más formas de orar';

  @override
  String get prayerMoment => 'Tu momento de oración';

  @override
  String get beStill => 'Quédate en silencio un momento';

  @override
  String get usePrayerBeginning =>
      'Usa esta oración como inicio y luego habla con tus propias palabras.';

  @override
  String get voiceStaysDevice =>
      'Tu voz permanece en este dispositivo. Puedes escucharla de nuevo o borrarla cuando quieras.';

  @override
  String get speakPrayer => 'Decir mi oración';

  @override
  String get silentMoment => 'Completar un momento en silencio';

  @override
  String recording(String time) {
    return 'Grabando · $time';
  }

  @override
  String get finishRecording => 'Terminar grabación';

  @override
  String get recordingLimit =>
      'Hasta dos minutos. Pulsa Terminar cuando estés listo.';

  @override
  String yourRecording(int seconds) {
    return 'Tu grabación · ${seconds}s';
  }

  @override
  String get listen => 'Escuchar';

  @override
  String get stopPlayback => 'Detener reproducción';

  @override
  String get saveComplete => 'Guardar y completar';

  @override
  String get recordAgain => 'Grabar de nuevo';

  @override
  String get completeWithoutAudio => 'Completar sin audio';

  @override
  String get leaveWithoutSaving => 'Salir sin guardar';

  @override
  String get momentWellSpent => 'Un momento bien vivido.';

  @override
  String prayerSaved(int count) {
    return 'Tu oración se ha guardado.\nRacha de $count días.';
  }

  @override
  String get newMilestone =>
      'Un nuevo logro en tu camino. Encuentra tu insignia en Tu progreso.';

  @override
  String get returnToday => 'Volver a Hoy';

  @override
  String get recordingPrivacy => 'Grabando';

  @override
  String get recordingStorageFull =>
      'El almacenamiento de grabaciones está lleno. Libera espacio en Ajustes o reflexiona en silencio.';

  @override
  String get recordingStartError =>
      'No se pudo iniciar la grabación. Aún puedes reflexionar en silencio.';

  @override
  String get recordingReviewError =>
      'La grabación se interrumpió. Reprodúcela, graba de nuevo o completa sin audio.';

  @override
  String get recordingPlaybackError =>
      'No se pudo reproducir esta grabación. Graba de nuevo o completa sin audio.';

  @override
  String get saveError =>
      'No se pudo guardar este momento. Inténtalo de nuevo.';

  @override
  String get alarmTime => 'Un momento para orar';

  @override
  String get alarmBody => 'Haz una pausa y da gracias con Cercano a Dios.';

  @override
  String get makeSpace => 'Haz un poco de espacio';

  @override
  String get prayerTime => 'Un tiempo para orar.';

  @override
  String get soundReminderMode => 'Modo de recordatorio con sonido';

  @override
  String get soundReminderDescription =>
      'Este iPhone admite recordatorios con notificación, no alarmas persistentes. El sonido depende de tus ajustes de notificaciones y Concentración. ¿Continuar con un recordatorio?';

  @override
  String get continueAction => 'Continuar';

  @override
  String get repeatOn => 'Repetir los días';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String nextAlarm(String date, String time) {
    return 'Siguiente: $date a las $time';
  }

  @override
  String get setupIncomplete =>
      'Configuración incompleta — pulsa Editar para reintentar';

  @override
  String get paused => 'En pausa';

  @override
  String get scheduled => 'Programada';

  @override
  String get permissionNeeded => 'Se necesita permiso del dispositivo';

  @override
  String get edit => 'Editar';

  @override
  String get delete => 'Borrar';

  @override
  String get addPrayerTime => 'Añadir un horario de oración';

  @override
  String get upToFive => 'Hasta cinco horarios de oración.';

  @override
  String get testAlarm => 'Probar en 10 segundos';

  @override
  String get stopAlarmNote =>
      'Detener siempre silencia la alarma. Nunca necesitas grabar una oración para descartarla.';

  @override
  String get openSettings => 'Abrir ajustes del dispositivo';

  @override
  String get journalTitle => 'Momentos para recordar.';

  @override
  String get journalSubtitle =>
      'Un registro privado del tiempo que dedicaste a Dios.';

  @override
  String get firstMomentHint =>
      'Tu primer momento aparecerá aquí. Comienza una oración desde Hoy.';

  @override
  String get spokenPrayer => 'Oración hablada';

  @override
  String get silentReflection => 'Reflexión en silencio';

  @override
  String get deleteRecordingTitle => '¿Borrar grabación?';

  @override
  String get deleteRecordingDescription =>
      'Tu momento completado y tu racha permanecerán.';

  @override
  String get deleteMomentTitle => '¿Borrar este momento?';

  @override
  String get deleteMomentDescription =>
      'Se eliminará la grabación y se recalculará tu progreso.';

  @override
  String get loadEarlier => 'Cargar momentos anteriores';

  @override
  String get progressTitle => 'Sigue estando presente.';

  @override
  String get smallMoments => 'Los pequeños momentos suman';

  @override
  String bestAndMoments(int best, int total) {
    return 'Mejor racha: $best días · $total momentos';
  }

  @override
  String get milestoneReached => 'Logro alcanzado';

  @override
  String get oneMoment => 'Un momento a la vez';

  @override
  String get progressDisclaimer =>
      'Estos logros celebran tu práctica. No miden tu fe. Un día perdido siempre es una invitación a comenzar de nuevo.';

  @override
  String get spaceTitle => 'Simple. Privado. Tuyo.';

  @override
  String storageUsage(String used) {
    return '$used MB de 100 MB';
  }

  @override
  String get storageNearLimit =>
      'Tus grabaciones se acercan al límite. Puedes liberar espacio sin perder tu racha.';

  @override
  String get storagePrivate =>
      'Tus grabaciones de voz permanecen en este dispositivo.';

  @override
  String get deleteAllRecordings => 'Borrar todas las grabaciones';

  @override
  String get deleteAllRecordingsTitle => '¿Borrar todas las grabaciones?';

  @override
  String get deleteAllRecordingsDescription =>
      'Se borrará todo el audio. Tus momentos, rachas e insignias permanecerán.';

  @override
  String get permissions => 'Permisos';

  @override
  String get permissionLabel => 'Acceso al micrófono y las alarmas';

  @override
  String get aboutData => 'Sobre tus datos';

  @override
  String get privacyDescription =>
      'Sin cuenta. Sin cargas. Sin anuncios. Tus oraciones se guardan de forma privada en este dispositivo. Desinstalar la app o perder el dispositivo puede borrar tu historial y tus grabaciones.';

  @override
  String get timezoneNote =>
      'Las rachas usan la fecha local al completar un momento. Viajar entre zonas horarias puede saltar o repetir un día. Siempre puedes comenzar de nuevo.';

  @override
  String get startFresh => 'Empezar de nuevo';

  @override
  String get resetTitle => '¿Restablecer Cercano a Dios?';

  @override
  String get resetDescription =>
      'Esto borra tu historial, audio, alarmas, rachas e insignias de este dispositivo. No se puede deshacer.';

  @override
  String get deleteAppData => 'Borrar todos los datos de la app';

  @override
  String get footer => 'Cercano a Dios · 0.1.0\nUn poco más cerca, cada día.';

  @override
  String get badgeFirst => 'Primer momento';

  @override
  String get badgeStreak3 => 'Tres días fieles';

  @override
  String get badgeStreak7 => 'Una semana de oración';

  @override
  String get badgeStreak30 => 'Treinta días juntos';

  @override
  String get badgeTotal10 => 'Diez momentos';

  @override
  String get badgeTotal50 => 'Cincuenta momentos';

  @override
  String get badgeMilestoneDescription => 'Logro alcanzado';

  @override
  String get badgeLockedDescription => 'Un momento a la vez';

  @override
  String get promptTitleP01 => 'Por este nuevo día';

  @override
  String get promptTextP01 =>
      'Señor, gracias por este nuevo día. Ayúdame a recibirlo con el corazón abierto.';

  @override
  String get promptTitleP02 => 'Un pequeño regalo';

  @override
  String get promptTextP02 =>
      'Padre celestial, hoy te doy gracias por ___. Ayúdame a reconocer tus regalos en lo cotidiano.';

  @override
  String get promptTitleP03 => 'Un corazón en paz';

  @override
  String get promptTextP03 =>
      'Jesús, acompáñame en mis preocupaciones. Enséñame a confiar en ti paso a paso.';

  @override
  String get promptTitleP04 => 'Por quienes amo';

  @override
  String get promptTextP04 =>
      'Señor, bendice a las personas que amo. Ayúdame a tratarlas con paciencia y bondad.';

  @override
  String get promptTitleP05 => 'Una pausa al anochecer';

  @override
  String get promptTextP05 =>
      'Padre, gracias por caminar conmigo hoy. Pongo este día en tus manos.';

  @override
  String get promptTitleP06 => 'Volver a empezar';

  @override
  String get promptTextP06 =>
      'Jesús misericordioso, ayúdame a comenzar de nuevo cuando falle y guíame hacia el bien.';

  @override
  String get promptTitleP07 => 'Un espíritu generoso';

  @override
  String get promptTextP07 =>
      'Señor, muéstrame a alguien a quien pueda ayudar. Hazme generoso con mi tiempo y atención.';

  @override
  String get promptTitleP08 => 'Por el pan de cada día';

  @override
  String get promptTextP08 =>
      'Padre, gracias por el alimento y el hogar que tengo. Acerca a mi corazón a quienes pasan necesidad.';

  @override
  String get promptTitleP09 => 'En el silencio';

  @override
  String get promptTextP09 =>
      'Espíritu Santo, calma el ruido que llevo dentro. Ayúdame a escuchar con un corazón dispuesto.';

  @override
  String get promptTitleP10 => 'Por mi trabajo';

  @override
  String get promptTextP10 =>
      'Jesús, guía el trabajo de mis manos. Que pueda servir a los demás con honestidad y cuidado.';

  @override
  String get promptTitleP11 => 'Cuando estoy cansado';

  @override
  String get promptTextP11 =>
      'Señor, te entrego mi cansancio. Ayúdame a descansar y recibir el cuidado que necesito.';

  @override
  String get promptTitleP12 => 'Un recuerdo agradecido';

  @override
  String get promptTextP12 =>
      'Padre, gracias por un momento de alegría que recuerdo hoy: ___.';

  @override
  String get promptTitleP13 => 'El regalo de la amistad';

  @override
  String get promptTextP13 =>
      'Señor, gracias por quienes caminan a mi lado. Ayúdame a ser un amigo fiel.';

  @override
  String get promptTitleP14 => 'Por el perdón';

  @override
  String get promptTextP14 =>
      'Padre misericordioso, dame valor para pedir perdón y gracia para perdonar a los demás.';

  @override
  String get promptTitleP15 => 'Con María';

  @override
  String get promptTextP15 =>
      'María, Madre de Jesús, ruega por mí mientras busco seguir hoy a tu Hijo.';

  @override
  String get promptTitleP16 => 'Una respuesta paciente';

  @override
  String get promptTextP16 =>
      'Espíritu Santo, ayúdame a hacer una pausa antes de hablar. Que mis palabras lleven paciencia y verdad.';

  @override
  String get promptTitleP17 => 'Por quienes están solos';

  @override
  String get promptTextP17 =>
      'Jesús, acércate a quienes se sienten solos. Muéstrame cómo ofrecer compañía.';

  @override
  String get promptTitleP18 => 'Confiar en la incertidumbre';

  @override
  String get promptTextP18 =>
      'Padre, no sé todo lo que traerá este día. Ayúdame a dar el siguiente paso bueno.';

  @override
  String get promptTitleP19 => 'Por la creación';

  @override
  String get promptTextP19 =>
      'Señor, gracias por la belleza de tu creación. Enséñame a cuidar nuestra casa común.';

  @override
  String get promptTitleP20 => 'Una sencilla ofrenda';

  @override
  String get promptTextP20 =>
      'Jesús, te ofrezco este pequeño momento. Ayúdame a crecer en fe, esperanza y amor.';

  @override
  String get appOpenError => 'No pudimos abrir tu diario de oración.';

  @override
  String get tryAgain => 'Intentar de nuevo';

  @override
  String get soundReminders => 'Recordatorios con sonido en este iPhone';

  @override
  String get ringingAlarms => 'Alarmas con Detener y Posponer';

  @override
  String deviceAccess(Object permission) {
    return 'Acceso del dispositivo: $permission';
  }

  @override
  String listenDuration(Object seconds) {
    return 'Escuchar · ${seconds}s';
  }

  @override
  String get deleteAudioKeepMoment => 'Borrar audio, conservar momento';

  @override
  String get deleteMoment => 'Borrar momento';

  @override
  String get monday => 'Lunes';

  @override
  String get tuesday => 'Martes';

  @override
  String get wednesday => 'Miércoles';

  @override
  String get thursday => 'Jueves';

  @override
  String get friday => 'Viernes';

  @override
  String get saturday => 'Sábado';

  @override
  String get sunday => 'Domingo';

  @override
  String get completed => 'completado';

  @override
  String get notCompleted => 'sin completar';

  @override
  String durationSeconds(Object seconds) {
    return '$seconds segundos';
  }

  @override
  String get promptCategoryMorning => 'Mañana';

  @override
  String get promptCategoryGratitude => 'Gratitud';

  @override
  String get promptCategoryPeace => 'Paz';

  @override
  String get promptCategoryFamily => 'Familia';

  @override
  String get promptCategoryHope => 'Esperanza';

  @override
  String get promptCategoryService => 'Servicio';

  @override
  String get promptCategoryFaith => 'Fe';

  @override
  String get microphoneLevel => 'Nivel de sonido del micrófono';

  @override
  String get promptCategoryEvening => 'Noche';
}
