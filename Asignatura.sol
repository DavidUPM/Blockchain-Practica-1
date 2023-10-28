// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 *  El contrato Asignatura que representa una asignatura de la carrera.
 *
 * Version Lite - Practicas
 */

contract Asignatura {
    /// Version 2022 Lite - Teoria
    string public version = "2022 Lite";

    /**
     * Direccion (address) del usuario que ha desplegado el contrato
     */
    address public owner;

    /// Nombre de la asignatura
    string public nombre;

    /// Curso academico
    string public curso;

    // Propiedad para guardar la dirección del coordinador de la asignatura
    address public coordinador;

    bool public cerrada;

    /// Datos de un alumno.
    struct DatosAlumno {
        string nombre;
        string dni;
        string email;
    }

    /// Acceder a los datos de un alumno dada su direccion.
    mapping(address => DatosAlumno) public datosAlumno;

    // Array con las direcciones de los alumnos matriculados.
    address[] public matriculas;

    // Asocia la dirección de un profesor (clave) con su nombre (valor)
    mapping(address => string) public datosProfesor;

    address[] public profesores;

    /**
     * Datos de una evaluacion.
     */
    struct Evaluacion {
        string nombre;
        uint fecha;
        uint porcentaje;
        uint notaMin;
    }

    /// Evaluaciones de la asignatura.
    Evaluacion[] public evaluaciones;

    /// Tipos de notas: sin usar, no presentado, y nota normal entre 0 y 1000.
    enum TipoNota {
        Empty,
        NP,
        Normal
    }

    /**
     * Datos de una nota.
     * La calificacion esta multiplicada por 100 porque no hay decimales.
     */
    struct Nota {
        TipoNota tipo;
        uint calificacion;
    }

    // Dada la direccion de un alumno, y el indice de la evaluacion, devuelve
    // la nota del alumno.
    mapping(address => mapping(uint => Nota)) public calificaciones;

    /**
     * Constructor del contrato Asignatura, el cual inicializa los parámetros iniciales.
     *
     * @param _nombre Nombre de la asignatura.
     * @param _curso Curso académico.
     *
     * Requiere que los argumentos suministrados no estén vacíos. Establece al desplegador
     * del contrato como propietario y asigna el nombre y curso a la asignatura.
     */
    constructor(string memory _nombre, string memory _curso) {
        require(
            bytes(_nombre).length != 0,
            "El nombre de la asignatura no puede ser vacio"
        );
        require(
            bytes(_curso).length != 0,
            "El curso academico de la asignatura no puede ser vacio"
        );

        owner = msg.sender;
        nombre = _nombre;
        curso = _curso;
    }

    /**
     * Función de recepción que revierte cualquier intento de transferir ether al contrato.
     *
     * Rechaza explícitamente la recepción de fondos.
     */
    receive() external payable {
        revert("No se permite la recepcion de dinero.");
    }

    /**
     * Obtiene la dirección del coordinador de la asignatura.
     *
     * @return coordinador La dirección del coordinador de la asignatura.
     */
    function getCoordinador() public view returns (address) {
        return coordinador;
    }

    /**
     * Establece la dirección del coordinador de la asignatura.
     *
     * Requiere que la función sea ejecutada únicamente por el propietario del contrato y que la asignatura esté abierta.
     *
     * @param _nuevaDireccion La nueva dirección del coordinador.
     */ function setCoordinador(
        address _nuevaDireccion
    ) public soloOwner soloAbierta {
        require(
            msg.sender == owner,
            "Solo el owner puede cambiar al coordinador"
        );
        coordinador = _nuevaDireccion;
    }

    /**
     * Cierra la asignatura, restringiendo la capacidad de modificarla.
     *
     * Requiere que la función sea llamada únicamente por el coordinador y que la asignatura no esté cerrada.
     */ function cerrar() public soloCoordinador soloAbierta {
        cerrada = true;
    }

    /**
     * Agrega un nuevo profesor a la asignatura.
     *
     * @param _profesorDireccion La dirección del nuevo profesor.
     * @param _nombre El nombre del profesor a agregar.
     *
     * Requiere que el nombre del profesor no esté vacío.
     */
    function addProfesor(
        address _profesorDireccion,
        string memory _nombre
    ) public soloOwner soloAbierta {
        require(bytes(_nombre).length != 0, "El nombre no puede estar vacio");
        if (
            keccak256(abi.encodePacked(datosProfesor[_profesorDireccion])) ==
            keccak256(abi.encodePacked(""))
        ) {
            datosProfesor[_profesorDireccion] = _nombre;
        }
    }

    /**
     * Obtiene el número total de profesores asociados a la asignatura.
     *
     * @return La cantidad de profesores registrados.
     */
    function profesoresLength() public view returns (uint) {
        return profesores.length;
    }

    error DNIExistente();

    /*
     * Matricula a un alumno automáticamente en la asignatura.
     *
     * @param _nombre El nombre del alumno a matricular.
     * @param _dni    El número de identificación del alumno a matricular.
     * @param _email  El correo electrónico del alumno a matricular.
     * @dev Requiere que el alumno no esté matriculado previamente.
     * Requiere que el nombre y el DNI no estén vacíos.
     * @error DNIExistente Lanza un error si el DNI ya existe en el registro de alumnos.
     */

    function automatricula(
        string memory _nombre,
        string memory _dni,
        string memory _email
    ) public soloNoMatriculados {
        require(bytes(_nombre).length != 0, "El nombre no puede ser vacio");
        require(bytes(_dni).length != 0, "El DNI no puede ser vacio");

        if (bytes(datosAlumno[msg.sender].dni).length != 0) {
            revert DNIExistente();
        }

        datosAlumno[msg.sender] = DatosAlumno(_nombre, _dni, _email);
        matriculas.push(msg.sender);
    }

    /**
     * Matricula a un alumno en la asignatura.
     *
     * @param _direccion La dirección del alumno a matricular.
     * @param _nombre    El nombre del alumno a matricular.
     * @param _dni       El número de identificación del alumno a matricular.
     * @param _email     El correo electrónico del alumno a matricular.
     * @dev Requiere que el que llama a la función sea el propietario (owner) del contrato.
     * Requiere que el nombre y el DNI no estén vacíos.
     * Requiere que el alumno no esté previamente matriculado.
     */
    function matricular(
        address _direccion,
        string memory _nombre,
        string memory _dni,
        string memory _email
    ) public soloOwner soloAbierta {
        require(msg.sender == owner, "Solo el owner puede matricular alumnos");
        require(bytes(_nombre).length != 0, "El nombre no puede ser vacio");
        require(bytes(_dni).length != 0, "El DNI no puede ser vacio");
        require(
            bytes(datosAlumno[_direccion].dni).length == 0,
            "El alumno ya esta matriculado"
        );

        datosAlumno[_direccion] = DatosAlumno(_nombre, _dni, _email);
        matriculas.push(_direccion);
    }

    /**
     * El numero de alumnos matriculados.
     *
     * @return El numero de alumnos matriculados.
     */
    function matriculasLength() public view returns (uint) {
        return matriculas.length;
    }

    /**
     * Permite a un alumno obtener sus propios datos.
     *
     * @return _nombre El nombre del alumno que invoca el metodo.
     * @return _email  El email del alumno que invoca el metodo.
     */
    function quienSoy()
        public
        view
        soloMatriculados
        returns (string memory, string memory, string memory)
    {
        DatosAlumno memory datos = datosAlumno[msg.sender];
        return (datos.nombre, datos.dni, datos.email);
    }

    /**
     * Crear una prueba de evaluacion de la asignatura. Por ejemplo, el primer parcial, o la practica 3.
     *
     * Las evaluaciones se meteran en el array evaluaciones, y nos referiremos a ellas por su posicion en el array.
     *
     * @param _nombre El nombre de la evaluacion.
     * @param _fecha  La fecha de evaluacion (segundos desde el 1/1/1970).
     * @param _porcentaje El porcentaje de puntos que proporciona a la nota final.
     *
     * @return La posicion en el array evaluaciones,
     */
    function creaEvaluacion(
        string memory _nombre,
        uint _fecha,
        uint _porcentaje,
        uint _notaMin
    ) public soloProfesor soloAbierta returns (uint) {
        require(
            bytes(_nombre).length != 0,
            "El nombre de la evaluacion no puede ser vacio"
        );

        uint notaMinSinDecimales = _notaMin * 100;

        evaluaciones.push(
            Evaluacion(_nombre, _fecha, _porcentaje, notaMinSinDecimales)
        );
        return evaluaciones.length - 1;
    }

    /**
     * El numero de evaluaciones creadas.
     *
     * @return El numero de evaluaciones creadas.
     */
    function evaluacionesLength() public view returns (uint) {
        return evaluaciones.length;
    }

    /**
     * Poner la nota de un alumno en una evaluacion.
     *
     * @param alumno        La direccion del alumno.
     * @param evaluacion    El indice de una evaluacion en el array evaluaciones.
     * @param tipo          Tipo de nota.
     * @param calificacion  La calificacion, multipilicada por 100 porque no hay decimales.
     */
    function califica(
        address alumno,
        uint evaluacion,
        TipoNota tipo,
        uint calificacion
    ) public soloProfesor soloAbierta soloAbierta {
        require(
            estaMatriculado(alumno),
            "Solo se pueden calificar a un alumno matriculado."
        );
        require(
            evaluacion < evaluaciones.length,
            "No se puede calificar una evaluacion que no existe."
        );

        uint calificacionSinDecimales = calificacion * 100;

        require(
            calificacionSinDecimales <= 1000,
            "No se puede calificar con una nota superior a la maxima permitida."
        );

        Nota memory nota = Nota(tipo, calificacionSinDecimales);

        calificaciones[alumno][evaluacion] = nota;
    }

    /**
     * Obtiene la calificación del alumno en una evaluación específica.
     *
     * @param evaluacion El índice de la evaluación en el array de evaluaciones.
     * @return tipo El tipo de nota que ha obtenido el alumno.
     * @return calificacion La calificación obtenida por el alumno en la evaluación.
     *
     * Requiere que el índice de la evaluación exista y devuelve el tipo de nota y la calificación
     * que el alumno ha obtenido en la evaluación indicada.
     */
    function miNota(
        uint evaluacion
    ) public view soloMatriculados returns (TipoNota tipo, uint calificacion) {
        require(
            evaluacion < evaluaciones.length,
            "El indice de la evaluacion no existe."
        );

        Nota memory nota = calificaciones[msg.sender][evaluacion];

        tipo = nota.tipo;
        calificacion = nota.calificacion;
    }

    /**
     * Obtiene la nota final del alumno.
     *
     * Devuelve la nota final del alumno que invoca este método. Esto se calcula a partir de
     * las calificaciones obtenidas en las evaluaciones ponderadas por sus respectivos porcentajes.
     * Se limita la nota final a 499 si hay alguna calificación NP y la nota final supera 499.
     *
     * @return El tipo de nota de la nota final y la nota final multiplicada por 100.
     * Si alguna calificación está vacía, devuelve (Empty, 0).
     * Si todas las calificaciones son NP, devuelve (NP, 0).
     * En otro caso, devuelve la nota final calculada aplicando los porcentajes adecuados.
     */
    function miNotaFinal()
        public
        view
        soloMatriculados
        returns (TipoNota, uint)
    {
        uint sumaPonderada = 0;
        uint totalPorcentaje = 0;
        for (uint i = 0; i < evaluaciones.length; i++) {
            Nota memory notaAlumno = calificaciones[msg.sender][i];
            if (notaAlumno.tipo == TipoNota.Empty) {
                return (TipoNota.Empty, 0);
            } else if (notaAlumno.tipo == TipoNota.Normal) {
                sumaPonderada += (notaAlumno.calificacion *
                    evaluaciones[i].porcentaje);
                totalPorcentaje += evaluaciones[i].porcentaje;
            }
        }

        if (totalPorcentaje == 0) {
            return (TipoNota.NP, 0);
        }

        uint notaFinalAlumno = (sumaPonderada * 100) / totalPorcentaje;

        // Limitar la nota final a 499 si hay alguna calificación NP y la nota final supera 499
        for (uint i = 0; i < evaluaciones.length; i++) {
            if (
                calificaciones[msg.sender][i].tipo == TipoNota.NP &&
                notaFinalAlumno > 499
            ) {
                notaFinalAlumno = 499;
                break;
            }
        }

        return (TipoNota.Normal, notaFinalAlumno);
    }

    /**
     * Obtiene la nota final de un alumno específico.
     *
     * Devuelve la nota final del alumno cuya dirección se pasa como parámetro. Esto se calcula a partir de
     * las calificaciones obtenidas en las evaluaciones ponderadas por sus respectivos porcentajes.
     * Se limita la nota final a 499 si hay alguna calificación NP y la nota final supera 499.
     *
     * @param _alumno La dirección del alumno del cual se desea obtener la nota final.
     *
     * @return El tipo de nota de la nota final y la nota final multiplicada por 100.
     * Si alguna calificación está vacía, devuelve (Empty, 0).
     * Si todas las calificaciones son NP, devuelve (NP, 0).
     * En otro caso, devuelve la nota final calculada aplicando los porcentajes adecuados.
     */
    function notaFinal(address _alumno) public view returns (TipoNota, uint) {
        uint sumaPonderada = 0;
        uint totalPorcentaje = 0;
        for (uint i = 0; i < evaluaciones.length; i++) {
            Nota memory notaAlumno = calificaciones[_alumno][i];
            if (notaAlumno.tipo == TipoNota.Empty) {
                return (TipoNota.Empty, 0);
            } else if (notaAlumno.tipo == TipoNota.Normal) {
                sumaPonderada += (notaAlumno.calificacion *
                    evaluaciones[i].porcentaje);
                totalPorcentaje += evaluaciones[i].porcentaje;
            }
        }

        if (totalPorcentaje == 0) {
            return (TipoNota.NP, 0);
        }

        uint notaFinalAlumno = (sumaPonderada * 100) / totalPorcentaje;

        for (uint i = 0; i < evaluaciones.length; i++) {
            if (
                calificaciones[_alumno][i].tipo == TipoNota.NP &&
                notaFinalAlumno > 499
            ) {
                notaFinalAlumno = 499;
                break;
            }
        }

        return (TipoNota.Normal, notaFinalAlumno);
    }

    /**
     * Comprueba si una dirección de alumno está matriculada en la asignatura.
     *
     * Dada la dirección de un alumno, este método verifica si esa dirección tiene un nombre asignado en los datos de alumnos,
     * lo que indica que está matriculado en la asignatura.
     *
     * @param alumno La dirección del alumno a verificar.
     *
     * @return true si la dirección de alumno está asociada a un nombre, es decir, está matriculado.
     */
    function estaMatriculado(address alumno) private view returns (bool) {
        string memory _nombre = datosAlumno[alumno].nombre;

        return bytes(_nombre).length != 0;
    }

    /**
     * Modificador para que una funcion solo la pueda ejecutar un alumno matriculado.
     */
    modifier soloMatriculados() {
        require(
            estaMatriculado(msg.sender),
            "Solo permitido a alumnos matriculados"
        );
        _;
    }

    /**
     * Solo permite la ejecución de la función a un alumno no matriculado en la asignatura.
     * Verifica si el remitente (msg.sender) no está matriculado en la asignatura.
     */
    modifier soloNoMatriculados() {
        require(
            !estaMatriculado(msg.sender),
            "Solo permitido a alumnos no matriculados"
        );
        _;
    }
    /**
     * Restringe la ejecución de la función únicamente al creador/desplegador del contrato.
     * Verifica si el remitente (msg.sender) coincide con el propietario (owner) del contrato.
     */
    modifier soloOwner() {
        require(
            msg.sender == owner,
            "Usted no ha creado/desplegado este contrato"
        );
        _;
    }
    /**
     * Restringe la ejecución de la función exclusivamente al coordinador de la asignatura.
     * Verifica si el remitente (msg.sender) coincide con la dirección del coordinador de la asignatura.
     */
    modifier soloCoordinador() {
        require(
            msg.sender == coordinador,
            "Usted no es coordinador de esta asignatura"
        );
        _;
    }
    /**
     * Limita la ejecución de la función solamente a profesores de la asignatura.
     * Verifica si el remitente (msg.sender) tiene asignado un nombre de profesor en los datos de profesor.
     */
    modifier soloProfesor() {
        require(
            keccak256((abi.encodePacked(datosProfesor[msg.sender]))) ==
                keccak256(abi.encodePacked("")),
            "Es necesario ser profesor de la asignatura"
        );
        _;
    }
    /**
     * Permite la ejecución de la función únicamente si la asignatura está abierta para modificaciones.
     * Verifica si la propiedad cerrada es false, es decir, si la asignatura está abierta.
     */
    modifier soloAbierta() {
        require(
            cerrada == false,
            "La asignatura no esta abierta a modificacion"
        );
        _;
    }
}
