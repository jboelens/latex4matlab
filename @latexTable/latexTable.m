% LATEXTABLE - The latexTable class provides an interface to generate LaTeX
% code for the 'table' environment and the amsmath package's bmatrix
% environment. Supported MATLAB types are numeric arrays, tables and
% symbolic variables. Modified from the original latexTable function by Eli
% Duenisch: https://github.com/eliduenisch/latexTable
% 
% This class may:
%   - Access your system clipboard (if you wish to copy the LaTeX code)
%   - Run system commands on your computer (to compile the LaTeX code to
%   generate a preview)
% 
% obj = latexTable() creates an object of the latexTable class.
% obj = latexTable(data) creates an object and sets the Data property.
% obj = latexTable(data,'Name',value) allows to specify additional options as
% name/value pairs. These options may also be set later by modifying the
% object's properties.
% 
% Name/value pairs include:
% 
% DataFormat        - 'compact', 'decimal', 'exponential' or 'fixedPoint'.
%                   See the dataFormat enumeration class for all options.
% 
% DataPrecision     - Number of significant digits.
% 
% Caption           - If you plan to create a table, you can set its
%                   caption.
% 
% Label             - If you plan to create a table, you can set its label.
% 
% Borders           - 'none', 'single' (default), 'all'
% 
% ColumnAlignment   - 'l', 'c' (default), 'r'
% 
% BookTabs          - true/false (default). Whether or not to use the
%                   booktabs package's toprule, midrule and bottomrule.
% 
% DataNaNString     - String to replace when a NaN value is encountered.
% 
% Placement         - 'h' (default), 't', 'p', 'b', 'H', '!', or ''.
% 
% RowLabels         - If you plan to create a table, you can add an extra
%                   column specifying row labels.
% 
% ColumnLabels      - If you plan to create a table, you can add an extra
%                   row specifying column labels.
% 
% Example:
% 
% % Create an arbitrary matrix.
% A = magic(5);
% 
% % Create an instance of the latexTable class.
% obj = latexTable(A,'Borders','none');
% 
% % Generate LaTeX code and display it in the command window.
% obj.makeTable();
% 
% ----------------------------------------------------------------------------------
%  Copyright (c) 2016, Eli Duenisch
%  Copyright (c) 2020, Jelle Boelens
%  All rights reserved.
%  
%  Redistribution and use in source and binary forms, with or without
%  modification, are permitted provided that the following conditions are met:
%  
%  * Redistributions of source code must retain the above copyright notice, this
%    list of conditions and the following disclaimer.
%  
%  * Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%  
%  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
%  AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
%  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
%  DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE
%  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
%  DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
%  SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
%  CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY,
%  OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
%  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

classdef latexTable < matlab.mixin.CustomDisplay & handle
    
    properties (Description = 'Settings', DetailedDescription = 'Basic')
        DataFormat dataFormat = dataFormat('compact')
        DataPrecision {mustBeNumeric} = 3
        Caption {char,string} = 'MyTableCaption'
        Label {char,string} = 'MyTableLabel'
        Borders {mustBeMember(Borders,{'none','single','all'})} = 'single'
    end
    
    properties(Description = 'Settings', DetailedDescription = 'Advanced')
        ColumnAlignment {mustBeMember(ColumnAlignment,{'l','c','r'})} = 'c'
        Booktabs logical = false
        DataNaNString {char,string} = '-'
        Placement {mustBeMember(Placement,{'h','t','p','b','H','!',''})} = 'h'
        RowLabels {char,string} = ''
        ColumnLabels {char,string} = ''
    end
    
    properties (Description = 'Data')
        Data
    end
    
    properties (Description = 'Output')
        Text
    end
    
    properties (Dependent,Hidden)
        DataCell
    end
    
    %% Constructor
    methods
        function obj = latexTable(varargin)
            % latexTable - makes latexTable object
            
            if nargin < 1
                return
            end
            
            if isnumeric(varargin{1}) || istable(varargin{1}) || isa(varargin{1},'sym')
                % Data was given as input
                varargin = [{'Data'}, varargin];
            end
            
            if isstruct(varargin{1})
                % Take structure as prop/val input
                res = varargin{1};
            else
                % set up input parser
                p = inputParser();
                
                mc = metaclass(obj);
                props = mc.PropertyList;
                isSetting = strcmpi({props.Description},'Settings');
                isData = strcmpi({props.Description},'Data');
                settings = {props(isSetting | isData).Name};
                cellfun(@(s) p.addParameter(s,[]), settings);
                
                % Parse inputs
                p.parse(varargin{:});
                res = [fieldnames(p.Results), struct2cell(p.Results)];
            end
            
            % Set fields of object
            for i = 1:size(res,1)
                prop = res{i,1};
                val = res{i,2};
                if ~isempty(val)
                    obj.(prop) = val;
                end
            end
        end
    end
    
    %% Methods to generate output
    methods (Description = 'Output',DetailedDescription = 'Generate code for a table:')
        function makeTable(obj)
            
            C = obj.DataCell;
            
            % Add row and column labels
            if ~isempty(obj.ColumnLabels) && ~isempty(obj.RowLabels)
                C = [{''}, obj.ColumnLabels; obj.RowLabels(:), C];
            elseif ~isempty(obj.ColumnLabels)
                C = [obj.ColumnLabels; C];
            elseif ~isempty(obj.RowLabels)
                C = [obj.RowLabels, C];
            end
            
            % make table header lines:
            hLine = '\hline';
            switch obj.Borders
                case 'all'
                    header = ['\begin{tabular}','{|',repmat([obj.ColumnAlignment,'|'],1,size(C,2)),'}'];
                case 'single'
                    header = ['\begin{tabular}','{',obj.ColumnAlignment,'|',repmat(obj.ColumnAlignment,1,size(C,2)-1),'}'];
                case 'none'
                    header = ['\begin{tabular}','{',repmat(obj.ColumnAlignment,1,size(C,2)),'}'];
            end
            latex = {['\begin{table}','[',obj.Placement,']'];'\centering';header};
            
            % generate table
            if obj.Booktabs
                latex(end+1) = {'\toprule'};
            end
            
            for i=1:size(C,1)
                if i==2
                    if obj.Booktabs
                        latex(end+1) = {'\midrule'};
                    elseif strcmpi(obj.Borders,'single')
                        latex(end+1) = {hLine};
                    elseif strcmpi(obj.Borders,'all')
                        latex(end+1) = {hLine};
                    end
                elseif strcmpi(obj.Borders,'all')
                    latex(end+1) = {hLine};
                    
                end
                
                rowStr = '';
                for j=1:size(C,2)
                    dataValue = C{i,j};
                    if iscell(dataValue)
                        dataValue = dataValue{:};
                    elseif isnan(dataValue)
                        dataValue = obj.DataNaNString;
                    elseif isnumeric(dataValue)
                        dataValue = num2str(dataValue,dataFormatArray{i,j});
                    end
                    dataValue = replace(dataValue,'\infty','$\infty$');
                    if j==1
                        rowStr = dataValue;
                    else
                        rowStr = [rowStr,' & ',dataValue];
                    end
                end
                latex(end+1) = {[rowStr,' \\']};
            end
            
            if obj.Booktabs
                latex(end+1) = {'\bottomrule'};
            end
            
            % make footer lines for table:
            tableFooter = {'\end{tabular}';['\caption{',obj.Caption,'}']; ...
                ['\label{table:',obj.Label,'}'];'\end{table}'};
            if strcmpi(obj.Borders,'all')
                latex = [latex;{hLine};tableFooter];
            else
                latex = [latex;tableFooter];
            end
            
            obj.Text = strjoin(latex,newline);
            
            % Clear command window
            clc();
            
            % print latex code to console:
            disp(char(latex));
            
            % Print link to copy the text
            fprintf('\n\n')
            objName = inputname(1);
            fprintf('<a href = "matlab: clipboard(''copy'',%s.text)">Copy to clipboard</a> | <a href = "matlab: %s.preview">Preview</a>',objName,objName)
            fprintf('\n\n')
        end
    end
    
    methods (Description = 'Output',DetailedDescription = 'Generate code for a bmatrix:')
        
        function makeBMatrix(obj)
            
            C = obj.DataCell;
            
            latex = {'$$\begin{bmatrix}'};
            
            for i=1:size(C,1)
                rowStr = '';
                for j=1:size(C,2)
                    dataValue = C{i,j};
                    if iscell(dataValue)
                        dataValue = dataValue{:};
                    elseif isnan(dataValue)
                        dataValue = obj.DataNaNString;
                    elseif isnumeric(dataValue)
                        dataValue = num2str(dataValue,dataFormatArray{i,j});
                    end
                    if j==1
                        rowStr = dataValue;
                    else
                        rowStr = [rowStr,' & ',dataValue];
                    end
                end
                latex(end+1,:) = {[rowStr,' \\']};
            end
            
            % make footer lines for table:
            tableFooter = {'\end{bmatrix}$$'};
            latex = [latex;tableFooter];
            
            obj.Text = strjoin(latex,newline);
            
            % Clear command window
            clc();
            
            % print latex code to console:
            disp(char(latex));
            
            % Print link to copy the text
            fprintf('\n\n')
            objName = inputname(1);
            fprintf('<a href = "matlab: clipboard(''copy'',%s.text)">Copy to clipboard</a> | <a href = "matlab: %s.preview">Preview</a>',objName,objName)
            fprintf('\n\n')
        end
        
    end
    
    %% Get/set methods
    methods
        function charCell = get.DataCell(obj)
            % Make cell based on data type
            switch class(obj.Data)
                case 'double'
                    numCell = num2cell(obj.Data);
                case 'table'
                    T = obj.Data;
                    numCell = table2cell(T);
                    if isempty(obj.ColumnLabels)
                        obj.ColumnLabels = T.Properties.VariableNames;
                    end
                    if isempty(obj.RowLabels)
                        obj.RowLabels = T.Properties.RowNames;
                    end
                case 'sym'
                    numCell = cell(size(obj.Data));
                    for i = 1:numel(obj.Data)
                        numCell{i} = char(obj.Data(i));
                    end
                otherwise
                    error('Data type %s not supported',class(obj.Data))
            end
            
            charCell = cell(size(numCell));
            
            % Make dataFormat array the same size as data
            df = obj.DataFormat;
            if size(df,1) == 1
                df = repmat(df,size(obj.Data,1),1);
            end
            if size(df,2) == 1
                df = repmat(df,1,size(obj.Data,2));
            end
            
            % Get a string such as %.3f
            format = df.toFormat(obj.DataPrecision);
            
            % Loop over columns: all values in one column have the same
            % type
            for i = 1:size(numCell,2)
                col = numCell(:,i);
                if isnumeric(col{1})
                    col = cellfun(@(n,f) sprintf(f,n),col,format(:,i),'UniformOutput',false);
                end
                
                % Change Inf to \infty
                isInf = strcmpi(col,'Inf');
                col(isInf) = repmat({'\infty'},nnz(isInf),1);
                
                % Assign column
                charCell(:,i) = col;
            end
        end
        
    end
    
    %% Display methods
    methods (Access = protected)
        
        function displayScalarObject(obj)
            % Get all properties
            mc = metaclass(obj);
            props = mc.PropertyList;
            
            % Take out hidden props
            props = props(~vertcat(props.Hidden));
            
            % Take out advanced settings
            props = props(~strcmpi({props.DetailedDescription},'Advanced'));
            
            % Property groups
            [disp_props,~,prop_idx] = unique({props.Description},'stable');
            
            % General header
            header = ['<strong>',mc.Name,'</strong>', ' object:', '\n'];
            
            % Create body in a loop
            body = '';
            
            % Determine width of first column
            colWidth = max(cellfun(@numel,{props.Name}));
            
            % Name of our object in the workspace
            objName = inputname(1);
            
            for i = 1:numel(disp_props)
                body = [body, '\n', '<strong>', disp_props{i},':', '</strong>'];
                propsi = props(prop_idx == i);
                for j = 1:numel(propsi)
                    if strcmpi(disp_props{i},'Settings')
                        if isnumeric(obj.(propsi(j).Name)) || islogical(obj.(propsi(j).Name))
                            propValStr = num2str(obj.(propsi(j).Name));
                        elseif ischar(obj.(propsi(j).Name))
                            propValStr = obj.(propsi(j).Name);
                        else
                            propValStr = '';
                        end
                        line = sprintf('%*s: %s',colWidth,propsi(j).Name,propValStr);
                    else
                        S = size(obj.(propsi(j).Name));
                        cl = class(obj.(propsi(j).Name));
                        line = sprintf('%*s: %ix%i %s',colWidth,propsi(j).Name,S(1),S(2),cl);
                    end
                    body = [body, '\n', line];
                end
                if strcmpi(disp_props{i},'Settings')
                    % Link to advanced settings
                    link = sprintf('<a href = "matlab: %s.%s">%s</a>',objName,'showAdvancedSettings','Show advanced settings');
                    body = [body,'\n', link, '\n'];
                else
                    body = [body, '\n'];
                end
            end
            
            % Links to output methods
            meth = mc.MethodList;
            isOutputMethod = strcmpi({meth.Description},'Output');
            meth = meth(isOutputMethod);
            footer = '';
            
            for i = 1:numel(meth)
                link = sprintf('<a href = "matlab: %s.%s">%s</a>',objName,meth(i).Name,meth(i).Name);
                line = [sprintf('%*s',max(cellfun(@numel,{meth.DetailedDescription})),meth(i).DetailedDescription), ' ', link];
                footer = [footer, '\n', line];
            end
            
            % Print everything
            fprintf(header);
            fprintf(body)
            fprintf(footer)
            fprintf('\n\n')
        end
        
    end
    
    methods (Hidden)
        preview(obj)
        
        function showAdvancedSettings(obj)
            % Get all properties
            mc = metaclass(obj);
            props = mc.PropertyList;
            
            % Take out advanced settings
            props = props(strcmpi({props.DetailedDescription},'Advanced'));
            
            % Determine width of first column
            colWidth = max(cellfun(@numel,{props.Name}));
            
            body = '<strong>Advanced Settings:</strong>';
            propsi = props;
            for j = 1:numel(propsi)
                if isnumeric(obj.(propsi(j).Name)) || islogical(obj.(propsi(j).Name))
                    propValStr = num2str(obj.(propsi(j).Name));
                elseif ischar(obj.(propsi(j).Name))
                    propValStr = obj.(propsi(j).Name);
                else
                    propValStr = '';
                end
                line = sprintf('%*s: %s',colWidth,propsi(j).Name,propValStr);
                body = [body, '\n', line];
            end
            body = [body, '\n', '\n'];
            fprintf(body)
        end
    end
end