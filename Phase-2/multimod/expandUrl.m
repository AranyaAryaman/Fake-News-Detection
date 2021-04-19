function expanded = expandUrl(urls,varargin)
%EXPANDURL return the expanded URLs from short URLs

removeParams = false;                                   % flag
% parse input arguments
if nargin < 1, error('Insufficient number of input arguments.'); end;
if ischar(urls), urls = string(urls); end;
if mod(nargin,2) == 0, error('Wrong number of input arguments.'); end;
if nargin > 1 && strcmpi(varargin{1},'RemoveParams')
    if strcmpi(varargin{2},'true') || varargin{2} == 1
        removeParams = true;
    end
end

shorteners = {'bit.ly','bitly.com','buff.ly', ...       % Url shorteners
    'dlvr.it','edut.to','fb.me','flip.it', ...
    'focus.de','goo.gl','ift.tt','k.ht', ...
    'linkis.com','lnkd.in','ln.is','news360.com','n.pr', ...
    'nyti.ms','ow.ly','pearltrees.com','pos.co.ke', ...
    'prosyn.org','s.hbr.org','sco.lt','shar.es', ...
    'tinyurl.com','to.pbs.org','trib.al','wp.me'};

expanded = strings(size(urls));                         % initialize

import  matlab.net.* matlab.net.http.*                  % http interface libs
for ii = 1:length(urls)                                 % for each url
    if contains(urls(ii),shorteners)                    % if shortened
        uri = URI(urls(ii));                            % create URI obj
        r = RequestMessage;                             % request object
        options = HTTPOptions('MaxRedirects',0);        % prevent redirect
        try                                             % try
            response = r.send(uri,options);             % send http request
            location = getFields(response,'Location');  % get location field
            url = location.Value;                       % get expanded URL
            if removeParams                             % if remove params
                expanded(ii) = stripParams(url);        % strip params
            else
                expanded(ii) = url;                     % add as is
            end
        catch                                           % if error
            if removeParams                             % if remove params
                 expanded(ii) = stripParams(urls(ii));  % strip params
            else
                expanded(ii) = urls(ii);                % copy as is
            end
        end
    else                                                % otherwise
        if removeParams                                 % if remove params
            expanded(ii) = stripParams(urls(ii));  % strip params
        else
            expanded(ii) = urls(ii);                    % copy as is
        end
    end
end

end

% helper function
function stripped = stripParams(url)
    s = split(url,'?');                                 % split by ?
    s = split(s(1),'#');                                % split by #
    stripped = s(1);                                    % return root url
end