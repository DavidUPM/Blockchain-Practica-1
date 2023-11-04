// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.16;

/**
 * Smart Contract que representa a una asignatura de Grado/Master
 * Version Full - David Álvarez Muñoz, Jose Luis Benítez, Saulo Nuez Ortega
 */

contract Asignatura {
    string public version = "2023 Full";

    // Direccion (address) del usuario que ha desplegado el contrato
    address public owner;

    /// Nombre de la asignatura
    string public nombre;

    /// Curso academico
    string public curso;

    /// Propiedad para guardar la dirección del coordinador de la asignatura
    address public coordinador;

    // Propiedad para indicar si la asignatura está abierta a modificacion o no
    bool public cerrada;

    /// Datos de un alumno
    struct DatosAlumno {
        string nombre;
        string dni;
        string email;
    }

    /// Acceder a los datos de un alumno dada su direccion.
    mapping(address => DatosAlumno) public datosAlumno;

    /// Array con las direcciones de los alumnos matriculados.
    address[] public matriculas;

    /// Asocia la dirección de un profesor (clave) con su nombre (valor)
    mapping(address => string) public datosProfesor;

    address[] public profesores;

    /// Datos de una evaluacion.
    struct Evaluacion {
        string nombre;
        uint256 fecha;
        uint256 porcentaje;
        uint256 notaMin;
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
        uint256 calificacion;
    }

    /// Dada la direccion de un alumno y el indice de la evaluacion, devuelve la nota del alumno.
    mapping(address => mapping(uint256 => Nota)) public calificaciones;

    /**
     * Constructor.
     *
     * @param _nombre Nombre de la asignatura.
     * @param _curso  Curso academico.
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

    // ----------------------------------------- FUNCIONES DE LECTURA -------------------------------//

    function getNombre() public view returns (string memory) {
        return nombre;
    }

    function getCurso() public view returns (string memory) {
        return curso;
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    /// Devuelve el coordinador de la asignatura
    function getCoordinador() public view returns (address) {
        return coordinador;
    }

    /// Devuelve el número de profesores de una asignatura
    function profesoresLength() public view returns (uint256) {
        return profesores.length;
    }

    /**
     * El numero de alumnos matriculados.
     *
     * @return El numero de alumnos matriculados.
     */
    function matriculasLength() public view returns (uint256) {
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
        returns (
            string memory,
            string memory,
            string memory
        )
    {
        DatosAlumno memory datos = datosAlumno[msg.sender];
        return (datos.nombre, datos.dni, datos.email);
    }

    /**
     * El numero de evaluaciones creadas.
     *
     * @return El numero de evaluaciones creadas.
     */
    function evaluacionesLength() public view returns (uint256) {
        return evaluaciones.length;
    }

    /**
     * Devuelve el tipo de nota y la calificacion que ha sacado el alumno que invoca el metodo en la evaluacion pasada como parametro.
     *
     * @param evaluacion Indice de una evaluacion en el array de evaluaciones.
     *
     * @return tipo         El tipo de nota que ha sacado el alumno.
     * @return calificacion La calificacion que ha sacado el alumno.
     */
    function miNota(uint256 evaluacion)
        public
        view
        soloMatriculados
        returns (TipoNota tipo, uint256 calificacion)
    {
        require(
            evaluacion < evaluaciones.length,
            "El indice de la evaluacion no existe."
        );

        Nota memory nota = calificaciones[msg.sender][evaluacion];

        tipo = nota.tipo;
        calificacion = nota.calificacion;
    }

    // Devuelve la nota final del alumno
    function miNotaFinal()
        public
        view
        soloMatriculados
        returns (TipoNota, uint256)
    {
        return calcularNotaFinal(msg.sender);
    }

    function notaFinal(address _alumno)
        public
        view
        soloCoordinador
        returns (TipoNota, uint256)
    {
        return calcularNotaFinal(_alumno);
    }

    /**
     * Consulta si una direccion pertenece a un alumno matriculado.
     *
     * @param alumno La direccion de un alumno.
     *
     * @return true si es una alumno matriculado.
     */
    function estaMatriculado(address alumno) private view returns (bool) {
        string memory _nombre = datosAlumno[alumno].nombre;

        return bytes(_nombre).length != 0;
    }

    //----------------------------------- FUNCIONES AUXILIARES ----------------------------//

    function calcularNotaFinal(address _alumno)
        private
        view
        returns (TipoNota, uint256)
    {
        uint256 nota = 0;
        uint256 totalPorcentaje = 0;

        for (uint256 i = 0; i < evaluaciones.length; i++) {
            Nota memory notaAlumno = calificaciones[_alumno][i];
            if (notaAlumno.tipo == TipoNota.Empty) {
                return (TipoNota.Empty, 0);
            } else if (notaAlumno.tipo == TipoNota.Normal) {
                nota += (notaAlumno.calificacion * evaluaciones[i].porcentaje);
                totalPorcentaje += evaluaciones[i].porcentaje;
            }
        }

        if (totalPorcentaje < 100) {
            if (totalPorcentaje == 0) {
                return (TipoNota.NP, 0);
            } else {
                if (nota > 499) {
                    nota = 499;
                }
            }
        }
        return (TipoNota.Normal, nota);
    }

    // ----------------------------------------- FUNCIONES DE ESCRITURA -------------------------------//

    /// Método para establecer la dirección del coordinador
    function setCoordinador(address _nuevaDireccion)
        public
        soloOwner
        soloAbierta
    {
        coordinador = _nuevaDireccion;
    }

    /// Método para cerrar asignatura e impedir su modificación
    function cerrar() public soloCoordinador soloAbierta {
        cerrada = true;
    }

    /// Método para añadir un profesor a la asignatura
    function addProfesor(address _profesorDireccion, string memory _nombre)
        public
        soloAbierta
    {
        require(bytes(_nombre).length != 0, "El nombre no puede estar vacio");
        bytes memory returnName = abi.encodePacked(
            datosProfesor[_profesorDireccion]
        );
        bytes memory expectedName = abi.encodePacked("");
        if (keccak256(returnName) == keccak256(expectedName)) {
            datosProfesor[_profesorDireccion] = _nombre;
            profesores.push(_profesorDireccion);
        }
    }

    /**
     * Los alumnos pueden automatricularse con el metodo automatricula.
     *
     * Impedir que se pueda meter un nombre vacio.
     *
     * @param _nombre El nombre del alumno.
     * @param _email  El email del alumno.
     * @param _dni El DNI del alumno
     */
    function automatricula(
        string memory _nombre,
        string memory _dni,
        string memory _email
    ) public soloNoMatriculados {
        require(bytes(_nombre).length != 0, "El nombre no puede ser vacio");
        require(bytes(_dni).length != 0, "El DNI no puede ser vacio");

        bytes memory dni_bytes = abi.encodePacked(datosAlumno[msg.sender].dni);

        if (dni_bytes.length != 0) {
            revert DNIExistente();
        } else {
            datosAlumno[msg.sender] = DatosAlumno(_nombre, _dni, _email);
            matriculas.push(msg.sender);
        }
    }

    /// Matricula un nuevo alumno en la asignatura
    function matricular(
        address _direccion,
        string memory _nombre,
        string memory _dni,
        string memory _email
    ) public soloOwner {
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
        uint256 _fecha,
        uint256 _porcentaje,
        uint256 _notaMin
    ) public soloProfesor soloAbierta returns (uint256) {
        require(
            bytes(_nombre).length != 0,
            "El nombre de la evaluacion no puede ser vacio"
        );
        evaluaciones.push(
            Evaluacion(_nombre, _fecha, _porcentaje, _notaMin) //_notaMin es la nota mínima multiplicada por 100 para evitar decimales
        );
        return evaluaciones.length - 1;
    }

    /**
     * Poner la nota de un alumno en una evaluacion.
     *
     * @param alumno        La direccion del alumno.
     * @param evaluacionIndex El indice de una evaluacion en el array evaluaciones.
     * @param tipo          Tipo de nota.
     * @param calificacion  La calificacion, multipilicada por 100 porque no hay decimales.
     */
    function califica(
        address alumno,
        uint256 evaluacionIndex,
        TipoNota tipo,
        uint256 calificacion
    ) public soloProfesor soloAbierta {
        require(
            estaMatriculado(alumno),
            "Solo se pueden calificar a un alumno matriculado."
        );
        require(
            evaluacionIndex < evaluaciones.length,
            "No se puede calificar una evaluacion que no existe."
        );

        require(
            calificacion <= 1000,
            "No se puede calificar con una nota superior a la maxima permitida."
        );

        Nota memory nota = Nota(tipo, calificacion);

        calificaciones[alumno][evaluacionIndex] = nota;
    }

    /// No se permite la recepcion de dinero.
    receive() external payable {
        revert("No se permite la recepcion de dinero.");
    }

    // ------------------------------ ERRORES ---------- //

    /// Error que indica que el DNI introducido ya ha sido utilizado anteriormente
    error DNIExistente();

    // -------------------------------- MODIFICADORES -------------------------- //

    /// Modificador para que una funcion solo la pueda ejecutar un alumno matriculado.
    modifier soloMatriculados() {
        require(
            estaMatriculado(msg.sender),
            "Solo permitido a alumnos matriculados"
        );
        _;
    }

    /// Modificador para que una funcion solo la pueda ejecutar un alumno no matriculado aun
    modifier soloNoMatriculados() {
        require(
            !estaMatriculado(msg.sender),
            "Solo permitido a alumnos no matriculados"
        );
        _;
    }

    /// Modificador para que una funcion solo la pueda ejecutar el creador del contrato
    modifier soloOwner() {
        require(
            msg.sender == owner,
            "Usted no ha creado/desplegado este contrato"
        );
        _;
    }

    /// Modificador para que una funcion solo la pueda ejecutar un coordinador
    modifier soloCoordinador() {
        require(
            msg.sender == coordinador,
            "Usted no es coordinador de esta asignatura"
        );
        _;
    }

    /// Modificador para que una funcion solo la pueda ejecutar un profesor
    modifier soloProfesor() {
        bytes memory obtainedResult = abi.encodePacked(
            datosProfesor[msg.sender]
        );
        bytes memory expectedResult = abi.encodePacked("");
        require(
            keccak256(obtainedResult) != keccak256(expectedResult),
            "Es necesario ser profesor de la asignatura"
        );
        _;
    }

    /// Modificador para que una funcion solo se pueda ejecutar si la asignatura está abierta a modificacion
    modifier soloAbierta() {
        require(
            cerrada == false,
            "La asignatura no esta abierta a modificacion"
        );
        _;
    }
}
