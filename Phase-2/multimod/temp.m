load fake_news                                              % load data
t = table;                                                  % initialize a table
t.names = arrayfun(@(x) x.status.user.name, ...             % get user names
    fake_news.statuses, 'UniformOutput', false);
t.names = regexprep(t.names,'[^a-zA-Z .,'']','');           % remove non-ascii
t.screen_names = arrayfun(@(x) ...                          % get screen names
    x.status.user.screen_name, fake_news.statuses, 'UniformOutput', false);
t.followers_count = arrayfun(@(x)  ...                      % get followers count
    x.status.user.followers_count, fake_news.statuses);
t = unique(t,'rows');                                       % remove duplicates
t = sortrows(t,'followers_count', 'descend');               % rank users
disp(t(1:10,:))                                             % show the table


dbtype expandUrl 25:32
expanded = char(expandUrl('http://trib.al/ZQuUDNx'));       % expand url
disp([expanded(1:70) '...'])

delimiters = {' ','$','/','.','-',':','&','*', ...          % remove those
    '+','=','[',']','?','!','(',')','{','}',',', ...
    '"','>','_','<',';','%',char(10),char(13)};
AFINN = readtable('AFINN/AFINN-111.txt', ...                % load score file
    'Delimiter','\t','ReadVariableNames',0);
AFINN.Properties.VariableNames = {'Term','Score'};          % add var names
stopwordsURL ='http://www.textfixer.com/resources/common-english-words.txt';
stopWords = webread(stopwordsURL);                          % read stop words
stopWords = split(string(stopWords),',');                   % split stop words
tokens = cell(fake_news.tweetscnt,1);                       % cell arrray as accumulator
expUrls = strings(fake_news.tweetscnt,1);                   % cell arrray as accumulator
dispUrls = strings(fake_news.tweetscnt,1);                  % cell arrray as accumulator
scores = zeros(fake_news.tweetscnt,1);                      % initialize accumulator
for ii = 1:fake_news.tweetscnt                              % loop over tweets
    tweet = string(fake_news.statuses(ii).status.text);     % get tweet
    s = split(tweet, delimiters)';                          % split tweet by delimiters
    s = lower(s);                                           % use lowercase
    s = regexprep(s, '[0-9]+','');                          % remove numbers
    s = regexprep(s,'(http|https)://[^\s]*','');            % remove urls
    s = erase(s,'''s');                                     % remove possessive s
    s(s == '') = [];                                        % remove empty strings
    s(ismember(s, stopWords)) = [];                         % remove stop words
    tokens{ii} = s;                                         % add to the accumulator
    scores(ii) = sum(AFINN.Score(ismember(AFINN.Term,s)));  % add to the accumulator
    if ~isempty( ...                                        % if display_url exists
            fake_news.statuses(ii).status.entities.urls) && ...
            isfield(fake_news.statuses(ii).status.entities.urls,'display_url')
        durl = fake_news.statuses(ii).status.entities.urls.display_url;
        durl = regexp(durl,'^(.*?)\/','match','once');      % get its domain name
        dispUrls(ii) = durl(1:end-1);                       % add to dipUrls
        furl = fake_news.statuses(ii).status.entities.urls.expanded_url;
        furl = expandUrl(furl,'RemoveParams',1);            % expand links
        expUrls(ii) = expandUrl(furl,'RemoveParams',1);     % one more time
    end
end


dict = unique([tokens{:}]);                                 % unique words
domains = unique(dispUrls);                                 % unique domains
domains(domains == '') = [];                                % remove empty string
links = unique(expUrls);                                    % unique links
links(links == '') = [];                                    % remove empty string
DTM = zeros(fake_news.tweetscnt,length(dict));              % Doc Term Matrix
DDM = zeros(fake_news.tweetscnt,length(domains));           % Doc Domain Matrix
DLM = zeros(fake_news.tweetscnt,length(links));             % Doc Link Matrix
for ii = 1:fake_news.tweetscnt                              % loop over tokens
    [words,~,idx] = unique(tokens{ii});                     % get uniqe words
    wcounts = accumarray(idx, 1);                           % get word counts
    cols = ismember(dict, words);                           % find cols for words
    DTM(ii,cols) = wcounts;                                 % unpdate DTM with word counts
    cols = ismember(domains,dispUrls(ii));                  % find col for domain
    DDM(ii,cols) = 1;                                       % increment DMM
    expanded = expandUrl(expUrls(ii));                      % expand links
    expanded = expandUrl(expanded);                         % one more time
    cols = ismember(links,expanded);                        % find col for link
    DLM(ii,cols) = 1;                                       % increment DLM
end
DTM(:,ismember(dict,{'#','@'})) = [];                       % remove # and @
dict(ismember(dict,{'#','@'})) = [];                        % remove # and @

NSR = (sum(scores >= 0) - sum(scores < 0)) / length(scores);% net setiment rate
figure                                                      % new figure
histogram(scores,'Normalization','probability')             % positive tweets
line([0 0], [0 .35],'Color','r');                           % reference line
title(['Sentiment Score Distribution of "Fake News" ' ...   % add title
    sprintf('(NSR: %.2f)',NSR)])
xlabel('Sentiment Score')                                   % x-axis label
ylabel('% Tweets')                                          % y-axis label
yticklabels(string(0:5:35))                                 % y-axis ticks
text(-10,.25,'Negative');text(3,.25,'Positive');            % annotate

count = sum(DTM);                                           % get word count
labels = erase(dict(count >= 40),'@');                      % high freq words
pos = [find(count >= 40);count(count >= 40)] + 0.1;         % x y positions
figure                                                      % new figure
scatter(1:length(dict),count)                               % scatter plot
text(pos(1,1),pos(2,1)+3,cellstr(labels(1)),...             % place labels
    'HorizontalAlignment','center');
text(pos(1,2),pos(2,2)-2,cellstr(labels(2)),...
    'HorizontalAlignment','right'); 
text(pos(1,3),pos(2,3)-4,cellstr(labels(3)));
text(pos(1,3:end),pos(2,3:end),cellstr(labels(3:end))); 
title('Frequent Words in Tweets Mentioning Fake News')      % add title
xlabel('Indices')                                           % x-axis label
ylabel(' Count')                                            % y-axis label
ylim([0 150])                                               % y-axis range


is_hash = startsWith(dict,'#') & dict ~= '#';               % get indices
hashes = erase(dict(is_hash),'#');                          % get hashtags
hash_count = count(is_hash);                                % get count
labels = hashes(hash_count >= 4);                           % high freq tags
pos = [find(hash_count >= 4) + 1; ...                       % x y positions
    hash_count(hash_count >= 4) + 0.1];         
figure                                                      % new figure
scatter(1:length(hashes),hash_count)                        % scatter plot
text(pos(1,1),pos(2,1)- .5,cellstr(labels(1)),...           % place labels
    'HorizontalAlignment','center');
text(pos(1,2:end-1),pos(2,2:end-1),cellstr(labels(2:end-1)));
text(pos(1,end),pos(2,end)-.5,cellstr(labels(end)),...
    'HorizontalAlignment','right');
title('Frequently Used Hashtags')                           % add title
xlabel('Indices')                                           % x-axis label
ylabel('Count')                                             % y-axis label
ylim([0 15])                                                % y-axis range

is_ment = startsWith(dict,'@') & dict ~= '@';               % get indices
mentions = erase(dict(is_ment),'@');                        % get mentions
ment_count = count(is_ment);                                % get count
labels = mentions(ment_count >= 10);                        % high freq mentions
pos = [find(ment_count >= 10) + 1; ...                      % x y positions
    ment_count(ment_count >= 10) + 0.1];     
figure                                                      % new figure
scatter(1:length(mentions),ment_count)                      % scatter plot
text(pos(1,:),pos(2,:),cellstr(labels));                    % place labels
title('Frequent Mentions')                                  % add title
xlabel('Indices')                                           % x-axis label
ylabel('Count')                                             % y-axis label
ylim([0 100])                                               % y-axis range

count = sum(DDM);                                           % get domain count
labels = domains(count > 5);                                % high freq citations
pos = [find(count > 5) + 1;count(count > 5) + 0.1];         % x y positions    
figure                                                      % new figure
scatter(1:length(domains),count)                            % scatter plot
text(pos(1,:),pos(2,:),cellstr(labels));                    % place labels
title('Frequently Cited Web Sites')                         % add title
xlabel('Indices')                                           % x-axis label
ylabel('Count')                                             % y-axis label
count = sum(DLM);                                           % get domain count
labels = links(count >= 15);                                % high freq citations
pos = [find(count >= 15) + 1;count(count >= 15)];           % x y positions    
figure                                                      % new figure
scatter(1:length(links),count)                              % scatter plot
text(ones(size(pos(1,:))),pos(2,:)-2,cellstr(labels));      % place labels
title('Frequently Cited Sources ')                          % add title
xlabel('Indices')                                           % x-axis label
ylabel('Count')                                             % y-axis label

users = arrayfun(@(x) x.status.user.screen_name, ...        % screen names
    fake_news.statuses, 'UniformOutput', false);
uniq = unique(users);                                       % remove duplicates
combo = [DTM DLM];                                          % combine matrices
UEM = zeros(length(uniq),size(combo,2));                    % User Entity Matrix
for ii = 1:length(uniq)                                     % for unique user
    UEM(ii,:) = sum(combo(ismember(users,uniq(ii)),:),1);   % sum cols
end
cols = is_hash | is_ment;                                   % hashtags, mentions
cols = [cols true(1,length(links))];                        % add links
UEM = UEM(:,cols);                                          % select those cols
ent = dict(is_hash | is_ment);                              % select entities
ent = [ent links'];                                         % add links

ment_users = uniq(ismember(uniq,mentions));                 % mentioned users
is_ment = ismember(ent,'@' + string(ment_users));           % their mentions
ent(is_ment) = erase(ent(is_ment),'@');                     % remove @
UUM = zeros(length(uniq));                                  % User User Matrix
for ii =  1:length(ment_users)                              % for each ment user
    row = string(uniq) == ment_users{ii};                   % get row
    col = ent == ment_users{ii};                            % get col
    UUM(row,ii) = UEM(row,col);                             % copy count
end

UEM(:,is_ment) = [];                                        % remove mentioned users
UEM = [UUM, UEM];                                           % add UUM to adj
nodes = [uniq; cellstr(ent(~is_ment))'];                    % create node list
s = sparse(UEM);                                            % sparse matrix
[i,j,s] = find(s);                                          % find indices

G = digraph(i,j);                                           % directed graph
G.Nodes.Name = nodes;                                       % add node names
figure                                                      % new figure
colormap cool                                               % set color map
deg = indegree(G);                                          % get indegrees
markersize = log(deg + 2) * 2;                              % indeg for marker size
plot(G,'MarkerSize',markersize,'NodeCData',deg)             % plot graph
labels = colorbar; labels.Label.String = 'Indegrees';                 % add colorbar
title('Graph of Tweets containing "Fake News"')             % add title
xticklabels(''); yticklabels('');                           % hide tick labels

bins = conncomp(G,'OutputForm','cell','Type','weak');       % get connected comps
binsizes = cellfun(@length,bins);                           % get bin sizes
[~,idx] = max(binsizes);                                    % find biggest comp
subG = subgraph(G,bins{idx});                               % create sub graph
figure                                                      % new figure
colormap cool                                               % set color map
deg = indegree(subG);                                       % get indegrees
markersize = log(deg + 2) * 2;                              % indeg for marker size
h = plot(subG,'MarkerSize',markersize,'NodeCData',deg);     % plot graph
c = colorbar; c.Label.String = 'In-degrees';                % add colorbar
title('The Largest Subgraph (Close-up)')                    % add title
xticklabels(''); yticklabels('');                           % hide tick labels
[~,rank] = sort(deg,'descend');                             % get ranking
top15 = subG.Nodes.Name(rank(1:15));                        % get top 15
labelnode(h,top15,top15 );                               	% label nodes
axis([-.5 2.5 -1.6 -0.7]);                                  % define axis limits                                % show 70 chars