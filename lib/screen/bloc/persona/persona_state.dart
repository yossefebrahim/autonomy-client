part of 'persona_bloc.dart';

abstract class PersonaEvent {}

class CreatePersonaEvent extends PersonaEvent {}

class ImportPersonaEvent extends PersonaEvent {
  final String words;

  ImportPersonaEvent(this.words);
}

class GetInfoPersonaEvent extends PersonaEvent {
  final String uuid;

  GetInfoPersonaEvent(this.uuid);
}

class NamePersonaEvent extends PersonaEvent {
  final String name;

  NamePersonaEvent(this.name);
}

class PersonaState {
  ActionState createAccountState = ActionState.notRequested;
  ActionState namePersonaState = ActionState.notRequested;
  ActionState importPersonaState = ActionState.notRequested;

  Persona? persona;

  PersonaState(
      {this.createAccountState = ActionState.notRequested,
      this.namePersonaState = ActionState.notRequested,
      this.importPersonaState = ActionState.notRequested,
      this.persona});

  PersonaState copyWith({
    ActionState? createAccountState,
    ActionState? namePersonaState,
    ActionState? importPersonaState,
    Persona? persona,
  }) {
    return PersonaState(
      createAccountState: createAccountState ?? this.createAccountState,
      namePersonaState: namePersonaState ?? this.namePersonaState,
      importPersonaState: importPersonaState ?? this.importPersonaState,
      persona: persona ?? this.persona,
    );
  }
}
