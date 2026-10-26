import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../configs/config.dart';
import '../../../data/local/pref.dart';
import 'bloc.dart';

class LanguageBloc extends Bloc<LanguageEvent, LanguageState> {
  LanguageBloc() : super(InitialLanguageState()) {
    on<LanguageChanged>(_onLanguageChanged);
  }

  Future<void> _onLanguageChanged(
    LanguageChanged event,
    Emitter<LanguageState> emit,
  ) async {
    if (event.locale == AppLanguage.defaultLanguage) {
      emit(LanguageUpdated());
    } else {
      emit(LanguageUpdating());
      AppLanguage.defaultLanguage = event.locale;
      await LocalPref.setString("language", event.locale.languageCode);
      emit(LanguageUpdated());
    }
  }
}
