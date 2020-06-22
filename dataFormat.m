classdef dataFormat < int16
    
    enumeration
        compact     (1)
        Compact     (2)
        fixedPoint  (3)
        decimal     (4)
        exponential (5)
        Exponential (6)
    end
    
    methods
        function c = toFormat(obj,precision)
            
            if size(precision,1) == 1
                precision = repmat(precision,size(obj,1),1);
            end
            if size(precision,2) == 1
                precision = repmat(precision,1,size(obj,2));
            end
            
            validateattributes(precision,{'numeric'},{'integer','size',size(obj)})
            
            N = numel(obj);
            if N > 1
                c = cell(size(obj));
                for i = 1:N
                    c{i} = toFormat(obj(i),precision(i));
                end
            else
                name = char(obj);
                letter = name(1);
                if strcmp(name,'compact'), letter = 'g'; end
                if strcmp(name,'Compact'), letter = 'G'; end
                c = sprintf('%%.%i%s',precision,letter);
            end
        end
    end
end