function SKYL_fraction = readValueFromSKYL_LUT(SZA_deg, Band, AOT550nm, typeAerosol)
    % Lee el valor de diffuse skylight en la LookUp Table de Feng Gao
    % guardada en el fichero EXCEL 'SKYL_LUT.xlsx', generado a partir del
    % fichero 'skyl_lut.dat' que viene en el packege 'actual_albedo_calculation' 
    directorio = '\\cendat2\lidar\Satelites\MODIS\Datos\MCD43B3_Albedo_Madrid';
    nombreFichero = 'SKYL_LUT.xlsx';
    EXCEL_sheet = [typeAerosol '_Band_' num2str(Band)];
    SKYL_LUT = xlsread(fullfile(directorio, nombreFichero), EXCEL_sheet);
    columnIndex = find(abs(SKYL_LUT(1, :) - AOT550nm) == min(abs(SKYL_LUT(1, :) - AOT550nm)));
    rowIndex = find(abs(SKYL_LUT(:, 1) - SZA_deg) == min(abs(SKYL_LUT(:, 1) - SZA_deg))); 
    SKYL_fraction = SKYL_LUT(rowIndex, columnIndex);
end