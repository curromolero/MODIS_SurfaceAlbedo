% Extraer datos de los ficheros MCD43B1 (coeficientes f) y SKYL_LUT
% de MODIS, interpolar para las lambdas de AERONET, calcular Albedo vs SZA
% y compararlo con el de AERONET
import matlab.io.hdfeos.*
structParam = struct('BRDF_Albedo_Parameters_Band1', [0, 0, 0], 'BRDF_Albedo_Parameters_Band2', [0, 0, 0], ...
                        'BRDF_Albedo_Parameters_Band3', [0, 0, 0], 'BRDF_Albedo_Parameters_Band4', [0, 0, 0], ...
                        'BRDF_Albedo_Parameters_Band5', [0, 0, 0], 'BRDF_Albedo_Parameters_Band6', [0, 0, 0], ...
                        'BRDF_Albedo_Parameters_Band7', [0, 0, 0], 'BRDF_Albedo_Parameters_vis', [0, 0, 0], ...
                        'BRDF_Albedo_Parameters_nir', [0, 0, 0], 'BRDF_Albedo_Parameters_shortwave', [0, 0, 0]);
cd('\\cendat2\lidar\\Satelites\MODIS\Datos\MCD43B3_Albedo_Madrid');
[ficheroMODIS_B1, directorio] = uigetfile('*B1*.hdf','Seleccione el fichero');
fechaAERONET = datevec('2013/06/28'); % MODIS 16-days avg. Afinando al día que interesa
if ~(ficheroMODIS_B1 == 0)
    % Extrae la fecha del nombre del fichero MODIS
    % MCD43B1.A2012225.h17v04.005.2012242130041.hdf
    structInfoMODIS = infoFicheroMODIS(ficheroMODIS_B1);
    dirMODIS_B1 = fullfile(directorio, ficheroMODIS_B1);
    structFile_B1 = hdfinfo(dirMODIS_B1, 'eos');
    % Grid details
    gfid = gd.open(dirMODIS_B1);
    GRID_NAME='MOD_Grid_BRDF';
    gridID = gd.attach(gfid, GRID_NAME);
    for i = 1:sum(~cellfun(@isempty,{structFile_B1.Grid.DataFields.Name})) 
        [data, lat, lon] = gd.readField(gridID, structFile_B1.Grid.DataFields(i).Name);
        [row_lat_AEMETpixel, col_lat_AEMETpixel] = find(abs(lat - 40.452) == min(min(abs(lat - 40.452))));
        row_lon_AEMETpixel = find(abs(abs(lon(:, col_lat_AEMETpixel(1))) - 3.742) == min(abs(abs(lon(:, col_lat_AEMETpixel(1))) - 3.742)));
        scale_factor = 0.001; % Reference: https://lpdaac.usgs.gov/dataset_discovery/modis/modis_products_table/mcd43b1
        coefF_AEMET = scale_factor * double(data(:, row_lon_AEMETpixel, col_lat_AEMETpixel(1)));
        structParam.(structFile_B1.Grid.DataFields(i).Name) = coefF_AEMET';
    end %for
    gd.detach(gridID);
    gd.close(gfid);
    % MODIS wavelengths
    % Band1: 620 - 670 nm (Red), Band2:	841 - 876 (NIR), Band3: 459 - 479 nm (Blue),
    % Band4: 545 - 565 nm (Green), Band5: 1230 - 1250 nm (1.2), Band6: 1628 - 1652 nm (1.6)
    % Band7: 2105 - 2155 nm (2.1), shortwave: 0.3 - 5.0 um, visible: 0.3 - 0.7 um
    % and near-infrared: 0.7 to 5.0 um (nir)  
    wvlMODIS = [200, 645, 859, 469, 555, 1240, 1640, 2130, 4000];
    % Busca los datos coincidentes temporalmente de AERONET
    version = 2;
    nivel = 15;
    [Albedos] = buscarAlbedosAERONET(fechaAERONET, version, nivel);
    wvlAERONET = [200, 440, 675, 870, 1020, 4000];
    % Conversion a albedo
    % WSA = fiso + fvol * (0.189184) + fgeo * (-1.377622);     
    % BSA = fiso + ...
    %   fvol * (-0.007574 - 0.070987 * szen_sqr + 0.307588 * szen_cub) + ...
    %   fgeo * (-1.284909 - 0.166314 * szen_sqr + 0.041840 * szen_cub);
    structWS_Constants = struct('WS_iso', {1.0}, 'WS_vol', {0.189184}, ...
                        'WS_geo', {-1.377622});
    structBS_Constants = struct('BS_g0_iso', {1.0}, 'BS_g0_vol', {-0.007574}, ...
                        'BS_g0_geo', {-1.284909}, 'BS_g1_iso', {0.0}, ...
                        'BS_g1_vol', {-0.070987}, 'BS_g1_geo', {-0.166314}, ...
                        'BS_g2_iso', {0.0}, 'BS_g2_vol', {0.307588}, ...
                        'BS_g2_geo', {0.04184});
    % Calcula WSA y BSA para cada banda y cada angulo SZA
    newBS_Albedo = zeros(length(Albedos.Fechas), 10);
    Albedo = zeros(length(Albedos.Fechas), 10);
    newWS_Albedo = zeros(1, 10);
    for indexBand = 1:10 % 7 bands + vis + nir + sw. No shape indicators
         newWS_Albedo(indexBand) = structWS_Constants.WS_iso*structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(1) + ...
                        structWS_Constants.WS_vol*structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(2) + ...
                        structWS_Constants.WS_geo*structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(3);
        for indexSZA = 1:length(Albedos.Fechas)
            SZArad = Albedos.SZA(indexSZA)*pi()/180;
            newBS_Albedo(indexSZA, indexBand) = (structBS_Constants.BS_g0_iso + ...
                        structBS_Constants.BS_g1_iso * SZArad^2 + ...
                        structBS_Constants.BS_g2_iso * SZArad^3) * ...
                        structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(1) + ...
                       (structBS_Constants.BS_g0_vol + ...
                        structBS_Constants.BS_g1_vol * SZArad^2 + ...
                        structBS_Constants.BS_g2_vol * SZArad^3) * ...
                        structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(2) + ...
                       (structBS_Constants.BS_g0_geo + ...
                        structBS_Constants.BS_g1_geo * SZArad^2 + ...
                        structBS_Constants.BS_g2_geo * SZArad^3) * ...
                        structParam.(structFile_B1.Grid.DataFields(indexBand).Name)(3);
            % Read LUT, typeAerosol = 'Con', other is 'Mar'
            SKYL_fraction = readValueFromSKYL_LUT(Albedos.SZA(indexSZA), indexBand, Albedos.AOT_550(indexSZA), 'Con');
            % Actual albedo = WSA * SKYL_fraction + BSA * (1 - SKYL_fraction)
            Albedo(indexSZA, indexBand) = (1 - SKYL_fraction) * newBS_Albedo(indexSZA, indexBand) + SKYL_fraction * newWS_Albedo(indexBand);
        end % for indexBand
    end % for indexSZA
    % Ficheros a generar para libRadTran, de 200 a 4000 nm, cada 1 nm
    wvl_inic = 200;
    wvl_fin = 4000;
    wvl_step = 1;
    datosFichero = zeros(length(wvl_inic:wvl_step:wvl_fin), 2);
    datosFichero(:, 1) = wvl_inic:wvl_step:wvl_fin;
    directorioDatos = '\\cendat2\lidar\\Satelites\MODIS\Datos';
    for indexTime = 1:length(Albedos.Fechas)
        % Fichero con datos MODIS
        nombreFicMODIS = sprintf('%s%s%s%s', 'albedo_MODIS_', datestr(Albedos.Fechas(indexTime), 'yyyymmdd'), '_', datestr(Albedos.Fechas(indexTime), 'HHMM'), '.dat');
        fileID = fopen(fullfile(directorioDatos, nombreFicMODIS),'w');
        datosFichero(:, 2) = interp1(wvlMODIS, AlbedoMODIS, datosFichero(:, 1));
        fprintf(fileID,'%6.0f %6.4f\n',datosFichero');
        fclose(fileID);
        % Fichero con datos AERONET
        nombreFicAERONET = sprintf('%s%s%s%s', 'albedo_AERONET_', datestr(Albedos.Fechas(indexTime), 'yyyymmdd'), '_', datestr(Albedos.Fechas(indexTime), 'HHMM'), '.dat'); 
        fileID = fopen(fullfile(directorioDatos, nombreFicAERONET),'w');
        datosFichero(:, 2) = interp1(wvlAERONET, AlbedoAERONET, datosFichero(:, 1));
        fprintf(fileID,'%6.0f %6.4f\n',datosFichero');
        fclose(fileID);
    end %for
    AlbedoAERONET = [0, Albedos.Albedo_440(1), Albedos.Albedo_675(1), ...
                    Albedos.Albedo_870(1), Albedos.Albedo_1020(1), 0];
    % Albedo at 200 nm and 4000 nm assumed equal to zero, for interpolation
    plot(wvlAERONET, AlbedoAERONET, 'x');
    legend_txt = strcat('AERONET@', char(datetime(datevec(Albedos.Fechas(1)),'Format','HH:mm')));
    hold on;
    AlbedoMODIS = [0, Albedo(1, 1), Albedo(1, 2), Albedo(1, 3), ...
         Albedo(1, 4), Albedo(1, 5), Albedo(1, 6), Albedo(1, 7), 0];
    plot(wvlMODIS, AlbedoMODIS, 'o');
    legend_txt = {legend_txt, strcat('MODIS@', char(datetime(datevec(Albedos.Fechas(1)),'Format','HH:mm')))};
    % Interpolate MODIS data into AERONET wavelengths
    AlbedoAERONET_MODIS = interp1(wvlMODIS, AlbedoMODIS, wvlAERONET);
    plot(wvlAERONET, AlbedoAERONET_MODIS, '*');
    legend_txt = [legend_txt, strcat('Interpolate@', char(datetime(datevec(Albedos.Fechas(1)),'Format','HH:mm')))];
    for indexSZA = 2:length(Albedos.Fechas)
        AlbedoAERONET = [0, Albedos.Albedo_440(indexSZA), ...
            Albedos.Albedo_675(indexSZA), Albedos.Albedo_870(indexSZA), ...
            Albedos.Albedo_1020(indexSZA), 0];
        plot(wvlAERONET, AlbedoAERONET, 'x');
        legend_txt = [legend_txt, char(datetime(datevec(Albedos.Fechas(indexSZA)),'Format','HH:mm'))];
        AlbedoMODIS = [0, Albedo(indexSZA, 1), Albedo(indexSZA, 2), ...
            Albedo(indexSZA, 3), Albedo(indexSZA, 4), Albedo(indexSZA, 5), ...
            Albedo(indexSZA, 6), Albedo(indexSZA, 7), 0];
        plot(wvlMODIS, AlbedoMODIS, 'o');
        % Interpolate MODIS data into AERONET wavelengths
        AlbedoAERONET_MODIS = interp1(wvlMODIS, AlbedoMODIS, wvlAERONET);
        plot(wvlAERONET, AlbedoAERONET_MODIS, '*');
        legend_txt = [legend_txt, char(datetime(datevec(Albedos.Fechas(indexSZA)),'Format','HH:mm'))];
    end %for
    hold off;
    xlabel('Wavelengths (nm)');
    ylabel('Albedo');
    title(['día AERONET elegido: ' char(datetime(fechaAERONET,'Format','dd/MM/yyyy'))]);
    legend(legend_txt);
    nombreFicheroFIG = sprintf('%s%s%s%s', 'paraPresentacion_Albedos_CompMODISyAERONET_', datestr(Albedos.Fechas(1), 'yyyymmdd'), '.fig');
    saveas(gca, nombreFicheroFIG);
    % Evolucion temporal a lo largo del dia para Band 1 (675), 2 (870)
    % y 3 (470) de MODIS y canales 440, 675 y 870 de AERONET
    plot(datenum(Albedos.Fechas), Albedos.Albedo_675, '-x');
    legend_txt = 'AERONET 675 nm';
    hold on;
    plot(datenum(Albedos.Fechas), Albedo(:, 1), 'o');
    legend_txt = {legend_txt, 'MODIS 645 nm'};
    plot(datenum(Albedos.Fechas), Albedos.Albedo_870, '-x');
    legend_txt = [legend_txt, 'AERONET 870 nm'];
    plot(datenum(Albedos.Fechas), Albedo(:, 2), 'o');
    legend_txt = [legend_txt, 'MODIS 859 nm'];
    plot(datenum(Albedos.Fechas), Albedos.Albedo_440, '-x');
    legend_txt = [legend_txt, 'AERONET 440 nm'];
    plot(datenum(Albedos.Fechas), Albedo(:, 3), 'o');
    legend_txt = [legend_txt, 'MODIS 470 nm'];
    hold off;
    xlabel('Hora');
    ylabel('Albedo');
    title(['día AERONET elegido: ' char(datetime(fechaAERONET,'Format','dd/MM/yyyy'))]);
    legend(legend_txt);
    nombreFicheroFIG = sprintf('%s%s%s%s', 'EvolucionDiariaAlbedos_CompMODISyAERONET_', datestr(Albedos.Fechas(1), 'yyyymmdd'), '.fig');
    saveas(gca, nombreFicheroFIG);
else
    msgbox('No se seleccionó ningún fichero. Procesamiento abortado');
end %if