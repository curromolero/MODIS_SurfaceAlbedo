function [Albedos] = buscarAlbedosAERONET(fecha, version, nivel)
    % Selecciona los valores CIMEL del día indicado
    directorio = ['\\cendat2\lidar\CIMEL AEMET\AOD_V2\' char(datetime(fecha,'Format','yyyy')) '\InversionsV2\Level' num2str(nivel)];
    nombreFicheroCIMEL = ['CIMEL_AEMET_DUBOVIKfile_' char(datetime(fecha,'Format','yy')) '0101_' char(datetime(fecha,'Format','yy')) '1231_Madrid_Version' num2str(version) '_Level' num2str(nivel) '.nc'];
    % Lee los valores del fichero netCDF con todo el año CIMEL
    ncid = netcdf.open(fullfile(directorio, nombreFicheroCIMEL), 'NC_NOWRITE');
    fechaAERONET = netcdf.getVar(ncid, netcdf.inqVarID(ncid,'Date(dd-mm-yyyy)'));
    horaAERONET = netcdf.getVar(ncid, netcdf.inqVarID(ncid,'Time(hh:mm:ss)'));
    % Si es una medida nocturna, representa los valores del dia anterior y
    % el siguiente. Si es diurna, los de ese día
    indicesFecha = find(fechaAERONET == datenum(fecha));
    if ~isempty(indicesFecha)
        % Atencion a los indices, se ha restado 1 porque parecia estar
        % desplazado pero no se ha comprobado. Verificar!!
        Albedo_440 = netcdf.getVar(ncid,netcdf.inqVarID(ncid,'albedo_440'), (indicesFecha(1)-1), length(indicesFecha));
        Albedo_675 = netcdf.getVar(ncid, netcdf.inqVarID(ncid,'albedo_675'), (indicesFecha(1)-1), length(indicesFecha));
        Albedo_870 = netcdf.getVar(ncid, netcdf.inqVarID(ncid,'albedo_870'), (indicesFecha(1)-1), length(indicesFecha));
        Albedo_1020 = netcdf.getVar(ncid, netcdf.inqVarID(ncid,'albedo-1020'), (indicesFecha(1)-1), length(indicesFecha));
        SZA = netcdf.getVar(ncid, netcdf.inqVarID(ncid,'average_solar_zenith_angle_for_flux_calculation'), (indicesFecha(1)-1), length(indicesFecha));
        AOT500nm = netcdf.getVar(ncid, netcdf.inqVarID(ncid,'AOT_500'), (indicesFecha(1)-1), length(indicesFecha));
        AngExp400870 = netcdf.getVar(ncid, netcdf.inqVarID(ncid,'alpha440-870'), (indicesFecha(1)-1), length(indicesFecha));
        % Convert AOT_500 into AOT_550 using alpha440-870
        AOT550nm = AOT500nm.*(550.0/500.0).^(-1*AngExp400870);
        Albedos = struct('Fechas', horaAERONET(indicesFecha), ...
            'Albedo_440', Albedo_440, 'Albedo_675', Albedo_675, ...
            'Albedo_870', Albedo_870, 'Albedo_1020', Albedo_1020, ...
            'SZA', SZA, 'AOT_550', AOT550nm);
    else
        Albedos = struct('Fechas', horaAERONET(indicesFecha), ...
            'Albedo_440', 0, 'Albedo_675', 0, 'Albedo_870', 0, ...
            'Albedo_1020', 0, 'SZA', 0, 'AOT_550', 0);
    end %if    
end %function