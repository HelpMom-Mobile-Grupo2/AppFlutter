import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../bloc/auth_bloc.dart';

class _TermsSection {
  const _TermsSection(this.title, this.body);

  final String title;
  final String body;
}

// Estructura basada en la plantilla de Termly (App Terms and Conditions),
// adaptada a HelpMom: simulación educativa, qué ve el acompañante,
// desvinculación y uso responsable de la SOS.
const _sections = [
  _TermsSection(
    '1. Aceptación',
    'Al marcar "Leí y acepto" y pulsar "Aceptar y continuar" aceptas estos '
        'términos. Si no estás de acuerdo, no uses la app. Para usar HelpMom '
        'debes tener 18 años o más.',
  ),
  _TermsSection(
    '2. HelpMom es una simulación educativa',
    'HelpMom – Modo Compañero es un proyecto académico del curso '
        '"Aplicaciones para dispositivos móviles" de la UPC. Las mediciones de '
        'salud son simuladas: no vienen de sensores reales, y el semáforo no '
        'es un diagnóstico. La app no reemplaza la atención médica. Ante '
        'cualquier duda o síntoma, la gestante debe acudir a su centro de '
        'salud.',
  ),
  _TermsSection(
    '3. Qué información ves como acompañante',
    'Solo ves el nombre de la gestante, el color del semáforo con un mensaje '
        'general, la semana de embarazo, las alertas "Pasa la Voz" que ella te '
        'envía y los tips del día. Nunca ves valores clínicos (como la '
        'frecuencia cardiaca del bebé o la temperatura), síntomas ni las '
        'conversaciones de la gestante, y la app nunca te los pedirá.',
  ),
  _TermsSection(
    '4. El vínculo con la gestante',
    'Te vinculas con el código que ella genera en su app. Ella puede '
        'desvincularte cuando quiera, sin necesidad de avisarte. Desde ese '
        'momento dejas de ver su información. Cada gestante puede tener un '
        'solo acompañante vinculado a la vez.',
  ),
  _TermsSection(
    '5. Uso responsable de las alertas y la SOS',
    'Las alertas sirven para coordinar la ayuda; no son un servicio de '
        'emergencias. Responde con honestidad: no marques "Voy en camino" si '
        'no vas a ir. Una alerta SOS significa que ella necesita ayuda urgente '
        'o que la app detectó una posible señal de alarma: comunícate con ella '
        'de inmediato y, si no responde o la situación lo amerita, llama al '
        '106 (SAMU). La app depende de internet y de un servidor que puede '
        'tardar en responder, así que nunca dependas solo de ella en una '
        'emergencia.',
  ),
  _TermsSection(
    '6. Usos permitidos y prohibidos',
    'Usa la app solo para acompañar a tu pareja. No compartas tu cuenta, no '
        'intentes acceder a datos de otras personas, no alteres ni sobrecargues '
        'el servicio, y no uses la información para vigilar, presionar o '
        'acosar a la gestante.',
  ),
  _TermsSection(
    '7. Tu cuenta',
    'Eres responsable de cuidar tu contraseña. El equipo del proyecto puede '
        'suspender las cuentas que no cumplan estos términos. Puedes cerrar '
        'sesión desde Perfil: al hacerlo, se borra todo lo que la app guardó '
        'en tu teléfono. Si quieres eliminar tu cuenta del servidor, pídeselo '
        'al equipo del proyecto.',
  ),
  _TermsSection(
    '8. Privacidad y datos',
    'En el servidor del proyecto se guardan tu nombre, tu correo y tus '
        'credenciales. En tu teléfono se guardan tu sesión, tus preferencias, '
        'el teléfono de tu pareja si lo ingresas y una copia de las alertas y '
        'los tips para verlos sin conexión. Estos datos se usan solo con fines '
        'académicos y no se venden ni se comparten con terceros.',
  ),
  _TermsSection(
    '9. Propiedad intelectual',
    'Los textos, el diseño y la guía semanal pertenecen al equipo del '
        'proyecto. Puedes usarlos de forma personal y sin fines comerciales.',
  ),
  _TermsSection(
    '10. Garantías y responsabilidad',
    'La app se ofrece "tal cual", sin garantía de que esté siempre '
        'disponible, de que las alertas lleguen a tiempo ni de que la '
        'información sea exacta. El equipo del proyecto no se hace '
        'responsable de las decisiones que se tomen solo a partir de la app.',
  ),
  _TermsSection(
    '11. Cambios en la app o en estos términos',
    'Podemos cambiar la app y estos términos. Si el cambio es importante, te '
        'pediremos que vuelvas a aceptarlos dentro de la app.',
  ),
  _TermsSection(
    '12. Ley aplicable',
    'Estos términos se rigen por las leyes de la República del Perú, '
        'incluida la Ley N.° 29733, Ley de Protección de Datos Personales.',
  ),
  _TermsSection(
    '13. Contacto',
    'Equipo HelpMom-Mobile-Grupo2, curso "Aplicaciones para dispositivos '
        'móviles", UPC. Puedes hacer tus consultas a través del docente del '
        'curso.',
  ),
];

/// P1b. Antes de usar la app hay que aceptar los términos. Desde Perfil se
/// abre con [readOnly] en true, solo para leerlos.
class TermsScreen extends StatefulWidget {
  const TermsScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  bool _accepted = false;

  void _accept() {
    context.read<AuthBloc>().add(const AuthTermsAccepted());
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y condiciones'),
        automaticallyImplyLeading: widget.readOnly,
      ),
      body: BlocListener<AuthBloc, AuthState>(
        listenWhen: (_, _) => !widget.readOnly,
        listener: (context, state) {
          final route = routeForAuthState(state);
          if (route != null) Navigator.pushReplacementNamed(context, route);
        },
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Última actualización: 6 de noviembre de 2026',
                    style: textTheme.bodySmall,
                  ),
                  for (final section in _sections) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      header: true,
                      child: Text(section.title, style: textTheme.titleMedium),
                    ),
                    const SizedBox(height: 4),
                    Text(section.body, style: textTheme.bodyMedium),
                  ],
                ],
              ),
            ),
            if (!widget.readOnly)
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 0, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CheckboxListTile(
                        value: _accepted,
                        onChanged: (value) =>
                            setState(() => _accepted = value ?? false),
                        controlAffinity: ListTileControlAffinity.leading,
                        title: const Text(
                          'Leí y acepto los Términos y condiciones',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilledButton(
                          onPressed: _accepted ? _accept : null,
                          child: const Text('Aceptar y continuar'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
