part of "home_bloc.dart";



abstract class HomeState extends Equatable {

  const HomeState();
  
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState{
  const HomeInitial();
}

class HomeLoading extends HomeState{
  const HomeLoading();
}

//Contiene el resumen completo del dia para pintar la home screen
class HomeLoaded extends HomeState{
  final RegistroDiario registroDiario;
  final List<Rutina> rutinas;

  const HomeLoaded({
    required this.registroDiario,
    required this.rutinas,
  });

  @override 
  List <Object?>get props => [registroDiario,rutinas];
}

  class HomeError extends HomeState{
    final String message;
    const HomeError(this.message);
    @override
    List<Object?> get props => [message];
  }

